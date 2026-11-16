<?php $page_title = 'Home'; include('includes/header.php'); ?>
        <main><!--Contains the main content of the webpage-->
        <section><!--Defines a section of the webpage-->
            <h2>Milk collected twice a day, paid once a month</h2><!--Displays heading for this section -->
            <p>Ereteti Dairy Sacco has collected milk on the Ngong road since 1998. Around eight hundred farmers deliver to us twice a day, and we pay for every accepted litre once a month.</p><!--Explains the Sacco's history-->
            <p>Any farmer on one of our three routes may join. You need a national ID and a bank account, and you may deliver from the day your membership number is issued.</p><!--Explains membership requirements-->
        </section><!--Ends section-->
        <section><!--groups the route information together as a seperate section-->
            <h2>Where we collect</h2>
            <ul><!--Creates an unordered list for the routes-->
                <li><a href="routes.php">Kiserian route</a></li><!--Link to the Kiserian route page-->
                <li><a href="routes.php">Ngong route</a></li><!--Link to the Ngong route page-->
                <li><a href="routes.php">Rongai route</a></li><!--Link to the Rongai route page-->
            </ul><!--Ends unordered list-->
        </section><!--Ends section-->
        <img src="img/collection-centre.jpg" alt="Farmers queuing with churns at the Kiserian centre"><!--Displays an image of farmers queuing with churns at the Kiserian collection centre-->
        </main><!--Ends main content section-->
        <?php include('includes/footer.php'); ?>
