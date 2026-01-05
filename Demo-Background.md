## Creating a Story boeard using Gemini

Think like an expert technical presales specialist and want to create demo of the entire Kong platform. I want to show how all the components of Kong fit together to provide full lifecycle api management. I want to make sure to include Insomnia, Kong gateway, service catalog, developer portal. I want to be able to configure the platform declaratively using Terraform. I will be using Github to store all my configurations in a repo and will be using github workflows to configure platform. the workflows should include validation and testing using the inso cli. It should be extensible so i can add metering and billing as well as logging in a future release. Start by creating storyboard "Day in the life of an Org that has adopted Kong". Include the personas and tools used and business value. Lets make this into a healthcare use case we can use the smile cdr as the backend to our api's.  

## Using api.dev I used the prompt to generate an OpenAPI Spec

I want to create an specification for FHIR that include Patient, Observation,encounter, condition and medication, I want it compatible withSmile CDR. https://smilecdr.com/docs/quickstart/smile_quickstart.html

## Environment setup

1) use the ./start_demo to start the smile cdr server.
2) Import the fhir.api open api spec file in insomnia