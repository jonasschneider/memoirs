Memoir markup language
===

Hello world:

    Irgendwo muss der Anfang sein.

    DB[:memoirs].insert(body: x["text"]+" - "+x["person"], editor: "Jonas", created_at: Time.at(x["created_at"]/1000))

Raw quotes:

    "There's an end to every beginning." - Mark Twayne

    DB[:memoirs].insert(body: x["text"]+" - "+x["person"], editor: "Jonas", created_at: Time.at(x["created_at"]/1000))
