<?php
    $path = "../../";
    require_once($path."OpenSiteAdmin/pages/pageHeader.php");

	//SECURITY CHECKING \ REDIRECT CHECKS

	//FUNCTION DEFINITIONS

	//BEGIN TABLE DEFINITION
	$fieldset = new Fieldset_Vertical($form->getFormType());

//    $customSelectOptions = DatabaseManager::checkError("custom database query here");
    $result = DatabaseManager::checkError("select `ID`,`title` from `bookTypes`");
    $books = array();
    while($row = mysqli_fetch_assoc($result)) {
        $books[$row["ID"]] = $row["title"];
    }
    $result = DatabaseManager::checkError("select `ID`,`name` from `borrowers`");
    $donators = array();
    while($row = mysqli_fetch_assoc($result)) {
        $donators[$row["ID"]] = $row["name"];
    }

	$keyField = $fieldset->addField(new Hidden("ID", "", null, false, false));
    $fieldset->addField(new Hidden("libraryID", "", null, false, true), $_SESSION["libraryID"]);
    $linkField = $fieldset->addField(new Select("bookID", "Book ID", $books, true, true));
    $fieldset->addField(new Select("donatorID", "Originator", $donators, true, false));
    $fieldset->addField(new Select("expires", "Expire Semester", array("0000-00-00"=>"never"), true, true));
    $fieldset->addField(new Checkbox("expired", "Expired", null, true, false));
    $fieldset->addField(new TextArea("comments", "Comments", array("rows"=>6, "cols"=>25), false, false));
//    $fieldset->addField(new Text(dbTitle, formTitle, options, showInListView?, required?));
    //-- end table definition

	$tableName = "books";
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