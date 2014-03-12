Memoir markup language
======================

Freistehender Text:

    Irgendwo muss der Anfang sein.

Einfaches Zitat:

    "There's an end to every beginning." - Mark Twayne

Dialog:

    [A] Ich bin Redner A.
    [B] Ich bin Redner B.

Dialog mit Aktionen und Parentheticals:

    [A] Ich bin Redner B.
    [B](überrascht) Ähm. Nein?
    (A haut B um)
    [A] Jetzt schon.


Typo-Sonderzeichen:

    --    <- En dash
    ---   <- Em dash


    def migrate(x, cat)
      cleaned = x["text"].gsub("\u2014", "---").gsub("\u2013", "--")

      if x["text"].match(/^"(.*)"$/m)
        DB[:memoirs].insert(category_id: cat, body: cleaned+" - "+x["person"], editor: "Jonas", created_at: Time.at(x["created_at"]/1000))
      else
        DB[:memoirs].insert(category_id: cat, body: cleaned, editor: x["person"], created_at: Time.at(x["created_at"]/1000))
      end
    end
