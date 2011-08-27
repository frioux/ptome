<?php
    $path = "../../";
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
        mail("bion@drewcrawfordapps.com", "TOME", $_POST["comment"], $headers);
        header("Location:".$path."index.php");
    }
?>

Having problems? Contact a TOME developer!
<br>
<br>
<form method="post" action="">
    <input type="hidden" name="session" value="<?php var_dump($_SESSION); ?>">
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