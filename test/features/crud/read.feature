Feature: CRUD Read
  must be able to read data form server

  Background:
    Given few documents in database:
      |label    |firstname|lastname|email                                |age|city             |password   |
      |employees|Edan     |Mann    |lacus.Aliquam.rutrum@tortordictum.com|50 |Flushing         |EEJ12LVR6NI|
      |employees|Lawrence |Horn    |Nulla@liberoet.co.uk                 |43 |ChapecÃ³         |QRN78YAL7ME|
      |employees|Lawrence |Horn    |Nulla123@liberoet.co.uk              |43 |ChapecÃ³         |QRN78YAL7ME|
      |employees|Allistair|Cole    |consequat@eget.co.uk                 |46 |Itzehoe          |KZM48URX9PW|
      |employees|Jarrod   |Hester  |convallis@lorem.edu                  |43 |Sterling Heights |PWG09HGA5PY|
      |employees|Lev      |Hobbs   |Aliquam@Donecnon.net                 |57 |Fontenoille      |FIA46ZXG9ZQ|
      |employees|Herrod   |Barber  |Fusce.aliquam@lectus.co.uk           |58 |Mï¿½nchengladbach|MQU80HPH9HZ|
      |employees|Alexander|Sargent |nisi@Vivamuseuismodurna.edu          |39 |Kessenich        |DAM13MSK8MO|
      |employees|Cedric   |Potter  |massa.Mauris.vestibulum@penatibus.com|36 |Thisnes          |ZAA37EDH0YN|
      |employees|Colby    |James   |ut.sem@euarcuMorbi.org               |51 |Montecarotto     |ZTQ04LYI8TB|
  Scenario: Reading single document
    When when i request for a document with
      """
        {
          "message": "fetch",
          "label": "employees",
          "id": "fetch#1",
          "data": {
            "firstname": "Edan",
            "lastname": "Mann"
          }
        }
      """
    Then I should see JSON response that contains
      """
        {
          "message": "fetched",
          "label": "employees",
          "id": "fetch#1",
          "data": {
            "firstname": "Edan",
            "lastname": "Mann",
            "email": "lacus.Aliquam.rutrum@tortordictum.com",
            "age": "50",
            "city": "Flushing",
            "password": "EEJ12LVR6NI"
          }
        }
      """
  Scenario: Reading multiple documents with "kind:all"
    When when i request for a document with
      """
        {
          "message": "fetch",
          "label": "employees",
          "id": "fetch#2",
          "kind": "all",
          "data": {
            "firstname": "Lawrence",
            "lastname": "Horn"
          }
        }
      """
    Then I should see JSON response that contains
      """
        {
          "message": "fetched",
          "label": "employees",
          "id": "fetch#2",
          "data": [
            {
              "firstname": "Lawrence",
              "lastname": "Horn",
              "email": "Nulla@liberoet.co.uk",
              "age": "43",
              "city": "ChapecÃ³",
              "password": "QRN78YAL7ME"
            },
            {
              "firstname": "Lawrence",
              "lastname": "Horn",
              "email": "Nulla123@liberoet.co.uk",
              "age": "43",
              "city": "ChapecÃ³",
              "password": "QRN78YAL7ME"
            }
          ]
        }
      """