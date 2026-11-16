<?php
// process-register.php — the page that answers the form
// post, because the form sends personal details that should not appear in the address bar.
$page_title = 'Welcome';
include('includes/header.php');
// The form sends the route as 1, 2 or 3; show the route name instead.
$routes = ['1' => 'Kiserian route', '2' => 'Ngong route', '3' => 'Rongai route'];
$route_name = isset($_POST['route']) ? ($routes[$_POST['route']] ?? $_POST['route']) : '';
?>
<main>
<?php if (isset($_POST['first_name'])) { ?>
<h2>Karibu, <?php echo $_POST['first_name']; ?>!</h2>
<p>We have your application for <strong><?php echo $route_name; ?></strong>.</p>
<p>We will call <strong><?php echo $_POST['phone']; ?></strong> to confirm your first delivery.</p>
<?php
// List every field the form sent.
echo '<ul>';
foreach ($_POST as $field => $value) {
    echo '<li>' . $field . ': ' . $value . '</li>';
}
echo '</ul>';
?>
<?php } else { ?>
<h2>No application</h2>
<p>Open the Join the Sacco form and send it.</p>
<?php } ?>
</main>
<?php include('includes/footer.php'); ?>
