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
   $fieldset = new Fieldset_Vertical($form->getFormType());
   $keyField = $fieldset->addField(new Hidden("ID", "", null, true, true));
   $fieldset->addField(new Text("name", "Name (First Last)", null, true, true));
   $fieldset->addField(new Text("secondContact", "Second Contact", null, true, true));
   $fieldset->addField(new LETUEmailField("email", "LeTourneau Email", null, true, true));
   $fieldset->addField(new Password("password", "Password", null, true, true));
   $fieldset->addField(new Hidden("firstLogin", "", null, true, true), 1);

   $row = new RowManager("users", $keyField->getName(), $id);
   $fieldset->addRowManager($row);
   $form->addFieldset($fieldset);
   $form->process();
   $form->display();

?>

<p>
Notes: 
<br />
<font color="red">*</font> fields are required.<br />
<font color="blue">*</font> This must be a LeTourneau Email address.  Knowing this, you can just put the part before the @-sign if you prefer and it will automatically be added.<br />
<font color="green">*</font> Example: "AIM: letubenaiah; Cell: (123) 234-4567"
</p>

<?php require_once($path."footer.php"); ?>
