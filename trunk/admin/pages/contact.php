<?php
    $path = "../../";
    $pageTitle = "Contact";
    if(!isset($_GET["login"])) {
        require_once($path."header.php");
    } else {
        session_start();
    }

    if(isset($_POST["submit"])) {
        $headers = "";
        if(isset($_POST["from"])) {
            $headers = 'From: '.$_POST["from"]."\r\n".
            'Reply-To: '.$_POST["from"];
        }
        mail("bion@drewcrawfordapps.com", "TOME", print_r($_REQUEST["session"], true)."\n\n".$_POST["comment"], $headers);
        header("Location:".$path."index.php");
    }
?>

Having problems? Contact a TOME developer!
<br>
<br>
<form method="post" action="">
    <input type="hidden" name="session" value="<?php print var_export($_SESSION, true); ?>">
    Your Email:
    <br>
    <input type="text" name="from"> (If you don't provide this, we can't respond to your questions)
    <br>
    <br>
    Comment/Question/etc:
    <br>
    <textarea name="comment"></textarea>
    <br>
    <input type="submit" name="submit" value="Submit">
</form>

<?php
    if(!isset($_GET["login"])) {
        require_once($path."footer.php");
    }
?>