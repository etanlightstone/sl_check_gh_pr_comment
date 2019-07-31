This checks for build failure based on ShiftLeft's vulnerabilitiy analysis, and should be used as a build step after you run sl analyze as follows in jenkins:

/usr/bin/sl_check_results.rb $GIT_COMMIT $GIT_BRANCH  <app_name>

make sure you move ghconfig.json  into your jenkins home/.shiftleft/  config directory, and modify the ghconfig.json to match your own GH repo and access token

 
