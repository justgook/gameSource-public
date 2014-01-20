Feature: CRUD Create
  must be able to create data on server

  Scenario: Creating single document
    When when i request for a document with
      """
        {
          "message": "create",
          "label": "test-employees-create",
          "id": "create#1",
          "data": {
            "firstname": "Edan234234234",
            "lastname": "M2423432ann"
          }
        }
      """
    Then I should see JSON response that contains
      """
        {
          "message": "created",
          "label": "test-employees-create",
          "id": "create#1",
          "data": {
            "firstname": "Edan234234234",
            "lastname": "M2423432ann"
          }
        }
      """