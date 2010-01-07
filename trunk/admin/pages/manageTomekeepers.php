<?php
    $path = "../../";
    require_once($path."OpenSiteAdmin/pages/pageHeader.php");

	//SECURITY CHECKING \ REDIRECT CHECKS

	//FUNCTION DEFINITIONS

	//BEGIN TABLE DEFINITION
	$fieldset = new Fieldset_Vertical($form->getFormType());

//    $customSelectOptions = DatabaseManager::checkError("custom database query here");
    $result = DatabaseManager::checkError("select * from `libraries`");
    $libraries = array();
    while($row = mysqli_fetch_assoc($result)) {
        $libraries[$row["ID"]] = $row["name"];
    }

	$keyField = $fieldset->addField(new Hidden("ID", "", null, false, false));
    $linkField = $fieldset->addField(new Text("username", "Username", array("maxlength"=>50), true, true));
    $fieldset->addField(new Text("name", "Display Name", array("maxlength"=>50), true, true));
    $fieldset->addField(new Text("email", "Email", array("maxlength"=>50), true, true));
    $fieldset->addField(new Select("libraryID", "Library", $libraries, true, true));
    $fieldset->addField(new Text("secondContact", "Second Contact", array("maxlength"=>50), true, true));
//    $fieldset->addField(new Text(dbTitle, formTitle, options, showInListView?, required?));
    //-- end table definition

	$tableName = "users";
	if(!isset($_GET["id"]) || empty($_GET["id"])) {
		$id = -1;
	} else {
		$id = $_GET["id"];
	}
	$row = new RowManager($tableName, $keyField->getName(), $id);
	$fieldset->addRowManager($row);

	$form->addFieldset($fieldset);

	//CREATE FORM
	$form->process();

	//INCLUDE HEADER FILE
	require_once($path."header.php");

    //custom header html goes here

	//CREATE LIST
	if(empty($_GET["id"]) && $mode != Form::ADD) {
		print $list->generateList($fieldset, $keyField, $linkField, $QS);
	} else {
		$form->display();
	}

    //custom footer html goes here

	//INCLUDE FOOTER FILE
	require_once($path."footer.php");
?>