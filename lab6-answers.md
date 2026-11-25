# Lab 6 — my answers

Name: Agrey Gorwa · Admission number:226504

1. In process-delivery.php, the browser already checks the member number. Why does PHP check it again? Name one way the browser's check can be skipped.
(PHP checks the member number again because the browser check can be skipped straight to the server.The server can't trust the browser, so it must check again.)
   
2. In my INSERT, bind_param has the letters 'issd'. What does each letter stand for, and which value does it go with?

   (i =integer-farmer_id, s =string -date, s =string - session, d =double (decimal) - litres.)

3. Why is Delete a small form sent by post, while Edit is a link?

   (delete is a POST form because it changes the database a link could be triggered by accident and delete data nobody meant to delete. Edit is just a link because it only opens the edit page, it doesn't change anything.)

4. Someone opens deliveries.php?date=' OR '1'='1 on my site. What happens, and why does my prepared statement not run it as SQL?

   (nothing bad happens the prepared statement sends the SQL first with a ?, then the date separately as data. The database treats ' OR '1'='1 as one date value that doesn't exist, so it finds 0 deliveries. It never becomes part of the SQL..)
