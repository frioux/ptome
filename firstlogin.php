<?php
    $path = "./";
    $pageTitle = "First Login";
    require_once($path."header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Fieldset.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."admin/scripts/LETUEmailField.php");

?>
<h1>First Login</h1>
<p>
You haven't set your user information yet.  Let's do that now!
</p>

<?php

   $username = $_SESSION["username"];
   $query = "SELECT ID
             FROM users
             WHERE users.username = \"$username\";";

   $resultSet = DatabaseManager::checkError($query);
   $row = DatabaseManager::fetchArray($resultSet);
   $id = $row[0];

   $form = new Form(Form::EDIT);
   $form = new Form(Form::EDIT, $path."index.php", $path."firstlogin.php");
   $form->setSubmitText("Save");
   $fieldset = new Fieldset_Vertical($form->getFormType());
   $keyField = $fieldset->addField(new Hidden("ID", "", null, true, true));
   $fieldset->addField(new Text("name", "Name (First Last)", null, true, true));
   $fieldset->addField(new Text("secondContact", "Second Contact (<font color=\"red\">*</font>)", null, true, true));
   $fieldset->addField(new LETUEmailField("email", "LeTourneau Email (<font color=\"green\">*</font>)", null, true, true));
   $fieldset->addField(new Password("password", "Password", null, true, true));
   $firstLoginField = new Hidden("firstLogin", "", null, true, true);
   $fieldset->addField($firstLoginField);

   $row = new RowManager("users", $keyField->getName(), $id);
   $fieldset->addRowManager($row);
   $form->addFieldset($fieldset);
   $form->process();
   $firstLoginField->setValue(1);
   $form->display();

?>

<p>
Notes:
</p>
<p>
* Required Fields<br />
<font color="red">*</font> Example: "AIM:
   <?php
      $escape = htmlentities("<screen name>");
      print $escape;
   ?>
; Cell: (123) 234-4567"<br /
<font color="green">*</font> This must be a LeTourneau Email address.
</p>

<?php require_once($path."footer.php"); ?>
