<?php
// header.php — the top of every page
?>
<!DOCTYPE html><!--Tells browser that this document use HTML5-->
<html lang="en"><!--Starts the html document and set page language to english-->
    <head><!--Contains info about webpage that is not displayed directly on the page -->
        <meta charset="utf-8"><!--Sets character encoding to UTF-8 so text and symbols are displayed correctly-->
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title><?php echo $page_title; ?> — Ereteti Dairy Sacco</title><!--sets title that appears in the browser tab-->
        <!---an exteranal css link-->
        <link  rel ="stylesheet" href="style.css"><!--Links to an external CSS file for styling the webpage-->
        <script src="js/main.js" defer></script>
    </head><!--Ends head section and starts body section of the webpage-->
    <body><!--Contains the visible content that is displayed on the webpage-->
        <header><!--Contains the header content of the webpage-->
            <h1><?php echo $page_title; ?></h1><!--Displays the main heading of the webpage-->
            <p>Milk collected twice a day, on three routes out of Ngong.</p><!--Provides brief description of sacco-->
        </header><!--Ends header section-->
        <nav><!--Contains the navigation links of the webpage-->
            <ul><!--Creates an unordered list for navigation links-->
                <li><a href="index.php">Home</a></li><!--Link to the home page-->
                <li><a href="about.php">About</a></li><!--Link to the about page-->
                <li><a href="routes.php">Our Routes</a></li><!--Link to the routes page-->
                <li><a href="contact.php">Contact</a></li><!--Link to the contact page-->
                <li><a href="register.php">Join</a></li><!--Link to the registration page-->
                <li><a href="deliveries.php">Deliveries</a></li><!--Link to the deliveries page-->
            </ul><!--Ends unordered list-->
        </nav><!--Ends navigation section-->
