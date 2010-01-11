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
    while($row = DatabaseManager::fetchAssoc($result)) {
        $libraries[$row["ID"]] = $row["name"];
    }

	$keyField = $fieldset->addField(new Hidden("ID", "", null, false, false));
    $linkField = $fieldset->addField(new Text("title", "Title", array("maxlength"=>100), true, true));
    $isbn1 = new Text("ISBN10", "ISBN-10", array("maxlength"=>10), true, false);
    $isbn2 = new Text("ISBN13", "ISBN-13", array("maxlength"=>13), true, false);
    $fieldset->addField($isbn1);
    $fieldset->addField($isbn2);
    $fieldset->addField(new Text("author", "Author", array("maxlength"=>50), true, true));
    $fieldset->addField(new Text("edition", "Edition", array("maxlength"=>20), true, false));
    $fieldset->addField(new TextArea("comments", "Comments", array("rows"=>6, "cols"=>25), true, false));
    $fieldset->addField(new Checkbox("usable", "Usable", null, true, false), 1);
//    $fieldset->addField(new Text(dbTitle, formTitle, options, showInListView?, required?));
    //-- end table definition

	$tableName = "bookTypes";
	if(!isset($_GET["id"]) || empty($_GET["id"])) {
		$id = -1;
	} else {
		$id = $_GET["id"];
	}
    $id = intval($id);
	$row = new RowManager($tableName, $keyField->getName(), $id);
	$fieldset->addRowManager($row);

	$form->addFieldset($fieldset);

	//CREATE FORM
    if($form->processable() && $isbn1->isEmpty() && $isbn2->isEmpty()) {
        print "Error: Must provide at least 1 ISBN number<br>";
    } else {
        $form->process();
    }

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