pipeline{
	agent any
      stages{
           stage('Git Checkout Stage'){
               steps{
		 echo 'Checkingout git for the code'
                 git 'https://github.com/prabhatraghav/star-agile-health-care.git'
		 echo 'Done: Checkingout the code'
                 }
           }
          stage('Maven Compile Stage'){
              steps{
		 echo 'Compiling the code'
                 sh 'mvn compile'
		 echo 'Done: Compiling the code'
	         }
           }
          stage('Maven Test Stage'){
              steps{
		 echo 'Testing the code'
                 sh 'mvn test'
		 echo 'Done: Testing the code'
	         }
           }
          stage('Maven QA Stage'){
              steps{
		 echo 'QA of the code'
                  sh 'mvn checkstyle:checkstyle'
		 echo 'Done: QA of the code'
                 }
           }
	     stage('Maven Clean Package Stage'){
		steps{
		 echo 'Packaging of the code'
                  sh 'mvn clean package'
		 echo 'Done: Packaging of the code'
    	         }
	   }
        }
}