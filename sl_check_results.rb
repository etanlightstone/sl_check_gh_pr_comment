#!/usr/bin/env ruby
require 'json'
require 'httparty'

commit_hash = ARGV[0]
branch_name = ARGV[1]
app_id =  ARGV[2]

file_name = File.expand_path('~') +"/.shiftleft/config.json"

# get sl_config["orgId"] and sl_config["uploadToken"] and  sl_config["ghtoken"]
sl_config = JSON.parse( File.read(file_name) )
gh_config = JSON.parse( File.read(File.expand_path('~') +"/.shiftleft/ghconfig.json" ) )
sl_config["accessToken"] = gh_config["sl_access_token"]

headers = {
  Accept: "application/vnd.github.groot-preview+json",
  "User-Agent": "Httparty"
}

response = HTTParty.get(gh_config["repo_url"]+"/commits/"+commit_hash+"/pulls",
                        :headers => headers)

pr_number = JSON.parse( response.body )[0]["number"]

puts "PR NUMBER!\n"
puts pr_number

vheaders = {
  Accept: "application/json",
  Authorization: "Bearer " + sl_config["accessToken"]
}
vbody = {
  "query": { "severityFilter": ["SEVERITY_HIGH_IMPACT"]}
}
vurl = "https://www.shiftleft.io/api/v3/public/org/"+sl_config["orgId"]+"/app/"+app_id+"/tag/branch/"+branch_name+"/build"

puts vurl
 
vresponse = HTTParty.get(vurl,
                        :headers => vheaders)
                  #      :body => vbody.to_json)

#puts headers
# {"success":true} or {"error":true," ..
build_status = JSON.parse(vresponse.body)
if build_status["success"] && build_status["success"] == "true"
  puts "SUCCESS: No build failing vulnerabilies found"
  exit(0);
else
  puts "FAILURE: ShiftLeft Found "+ build_status["highImpactResults"]+ " Build failing vulnerabilities"

  vuln_url = "https://www.shiftleft.io/api/v3/public/org/"+sl_config["orgId"]+"/app/"+app_id+"/version/"+ commit_hash +"/vulnerabilities"
  vuln_response = HTTParty.post(vuln_url,
                         :headers => vheaders,
                         :body => vbody.to_json)
  #puts vuln_response.body
  vuln_list = JSON.parse(vuln_response.body)["vulnerabilities"];
  vuln_text = "\n\n"

  vuln_list.each {|v|
   #puts v["vulnerability"]["title"]
   vuln_text += v["vulnerability"]["title"] + "\n"
  }


  gh_headers = {
    Authorization: "token " + gh_config["ghtoken"],
    "User-Agent": "Httparty"
  }
  body = {body: "FAILURE: ShiftLeft Found "+ build_status["highImpactResults"]+
  " Build failing vulnerabilities\n Details: https://www.shiftleft.io/violationlist/"+app_id+"?apps="+app_id+"&isApp=1" + vuln_text}

  ghurl = gh_config["repo_url"]+"/issues/"+ pr_number.to_s+"/comments"
  puts "commenting on GH PR..."
  ghresponse = HTTParty.post(ghurl,
                         :headers => gh_headers,
                         :body => body.to_json)
  # puts ghresponse.body

  puts ghresponse.message
  exit(1);
end

