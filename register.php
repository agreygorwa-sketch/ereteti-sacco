<?php $page_title = 'Join the Sacco'; include('includes/header.php'); ?>
    <main>
        <p>Any dairy farmer within reach of one of our three routes may apply to join Ereteti. You will need your national ID number and a phone we can reach you on. Once your membership number is issued you may deliver from that day, and you are paid once a month for the litres we accept.</p>
        <form action="process-register.php" method="post"><!--creates a form for users to fill out -->
        <fieldset><!--Groups applicants details together-->
            <legend>Your Details</legend><!--Gives the fieldset a title-->
            <label for="first-name">First name</label><!--Creates a label for the first name input field-->
            <input type="text" id="first-name" name="first_name" required><!--Creates a text box for entering the first name-->
            <label for="last-name">Last name</label>
            <input type="text" id="last-name" name="last_name" required>
            <label for="national-id">National ID number</label>
            <input type="text" id="national-id" name="nation_id" required>
            <label for="phone">Phone number</label>
            <input type="tel" id="phone" name="phone" pattern="07[0-9]{8}" title="Ten digits, starting 07" placeholder="07XXXXXXXX" required><!--Creates a phone input with required kenyan number format-->
        </fieldset><!--Ends fieldset-->
        <fieldset>
            <legend>Your route</legend>
            <label for="route">Route</label>
            <select id="route" name="route" required><!--Creates a dropdown list for selecting a route-->
                <option value="">Choose a route</option><!--Provides instructions for the list-->
                <option value="1">Kiserian route</option><!--Provides the option for Kiserian route-->
                <option value="2">Ngong route </option>
                <option value="3">Rongai route</option>
            </select>
            <label for="date-joined">Date of joining</label>
            <input type="date" id="date-joined" name="date_joined" max="2026-09-24" required><!--Creates a date field and prevents dates after 24th September 2026-->
        </fieldset>
        <label for="rules">
        <input type="checkbox" id="rules" name="rules" required><!--Creates a checkbox for agreeing to the rules-->
        I accept the sacco's rules </label>
        <button type="submit">Apply to join</button><!--Creates a submit button for the form-->
        </form>
    </main>
    <?php include('includes/footer.php'); ?>
