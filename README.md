# README

To make it easy I've deployed the app on heroku and here's the endpoint you can use to test it:


Here are some examples of how to use the endpoint:
https://hey-bud-challenge-b6e22a301aaf.herokuapp.com/api/v1/restaurants?city=New%20York&neighborhood=West%20Village&cuisine=italian
https://hey-bud-challenge-b6e22a301aaf.herokuapp.com/api/v1/restaurants?city=New%20York&neighborhood=West%20Village&cuisine=mexican
https://hey-bud-challenge-b6e22a301aaf.herokuapp.com/api/v1/restaurants?&neighborhood=West%20Village&cuisine=indian
https://hey-bud-challenge-b6e22a301aaf.herokuapp.com/api/v1/restaurants?city=New%20York&cuisine=indian
https://hey-bud-challenge-b6e22a301aaf.herokuapp.com/api/v1/restaurants?city=New%20York&neighborhood=West%20Village
https://hey-bud-challenge-b6e22a301aaf.herokuapp.com/api/v1/restaurants?latitude=40.74066&longitude=-73.9747072&cuisine=american


Solution: 
  I've first used Google Places API to get the list of restaurants and then used OpenAI to enrich the data.
  I've used Redis to cache the results for 10 minutes to improve the performance.
  I've added some error handling to the endpoint to return the appropriate response.

Bonus:
  As a Bonus I've implemented additional feature where if there is email in the request parameters, I've uploaded the data in a google spreadsheet and shared it with the provided email.

Design considerations:
  1. I've services for OpenAI and Google Places with room to add more LLM providers and SearchAPI providers in the future.
  2. I've used api/v1 for endpoints to make it easy to add a new version in the future and to add a front end app that can leverage the API for a platform.
  3. As more resources are added like restaurants, we can have more controllers and endpoints for CRUD operations.
  4. I've added modeling for Restaurants to make it more structured and pass it around different services but didn't use any ORM to keep it simple.
  5. I've deployed the app on heroku and enabled auto-deploy to make it easy to deploy and scale with room to integrate a CI/CD pipeline in the future.
  6. I've created restaurant_service.rb to keep all the business logic of data aggregation and enrichment in one place.
  7. As we use more external APIs, new clients can be created and those clients can be used in restaurant_service.rb to aggregate, enrich, and consolidate data from multiple sources in a single places.
  8. I've used _service.rb for services used internally to talk to models(DB) and external APIs using _client.rb files
  9. I've kept the controller lean and simple where it will raise specific errors for that endpoint, create or fetch data from the database, and call the services for processing the request.
  10. The client files are basically an interface to the external APIs and their function is only to make REST calls to external APIs and capture and return the resposne and services handle the transformation and processing of data and saved to db if necessary.
  11. I've created a concern called geolocatable.rb to showcase the handling of different logics by decoupling it from the model without using inheritance, it's kind of ruby's version of interfaces but we can also implement the functions in the concern that can be shared across different classes and leave som empty for overloading, but it doesn't enforce the class to implement them. This is a powerful tool in Rails to package certain re-usable fields and their logic in one place and include them in the model as needed. For example If we later have model like venue or something which is different from restaurant but both are geolocatable.
  12. I've used the similar concept in controllers to handle the errors in one place and then include it in the base controller from which all the other controllers inherit. which keeps the code clean and DRY. so any errors that might occur in services, clients etc. are all propagated to the controller and can be handled in a single place. This is a simple implementation that can be extended later to handle more complicated use cases.


  P.S : Feel free to email me any questions you might have.
