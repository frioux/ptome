<?php
    $path = "../../";
    require_once($path."OpenSiteAdmin/pages/pageHeader.php");

	//SECURITY CHECKING \ REDIRECT CHECKS

	//FUNCTION DEFINITIONS

	//BEGIN TABLE DEFINITION
	$fieldset = new Fieldset_Vertical($form->getFormType());

//    $customSelectOptions = DatabaseManager::checkError("custom database query here");
    $result = DatabaseManager::checkError("select `ID`, `title` from `bookTypes`");
    $books = array();
    while($row = mysqli_fetch_assoc($result)) {
        $books[$row["ID"]] = $row["title"];
    }
    $result = DatabaseManager::checkError("select `ID`,`name` from `borrowers`");
    $borrowers = array();
    while($row = mysqli_fetch_assoc($result)) {
        $borrowers[$row["ID"]] = $row["name"];
    }

    $now = date("Y-m-d H:i:s");

	$keyField = $fieldset->addField(new Hidden("ID", "", null, false, false));
    $linkField = $fieldset->addField(new Select("bookID", "Book", $books, true, true));
    $fieldset->addField(new Hidden("tomekeeperID", "", null, false, true), $_SESSION["ID"]);
    $fieldset->addField(new Select("borrowerID", "Borrower", $borrowers, true, true));
    $fieldset->addField(new Hidden("out", "", null, true, true), $now);
    $fieldset->addField(new Hidden("in", "", null, true, false), $now);
//    $fieldset->addField(new Text(dbTitle, formTitle, options, showInListView?, required?));
    //-- end table definition

	$tableName = "checkouts";
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