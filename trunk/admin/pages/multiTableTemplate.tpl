<?php
    $path = "../../";
    require_once($path."OpenSiteAdmin/pages/pageHeader.php");

	//SECURITY CHECKING \ REDIRECT CHECKS

	//FUNCTION DEFINITIONS

	//BEGIN TABLE DEFINITION
    //----TABLE 1----
	$fieldset = new Fieldset_Vertical($form->getFormType());

	$keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $linkField = $fieldset->addField(new Text("title", "Title", array("maxlength"=>30), true, true));
//    $fieldset->addField(new Text(dbTitle, formTitle, options, showInListView?, required?));
    //-- end table definition

	$tableName = "";
	if(!isset($_GET["id"]) || empty($_GET["id"])) {
		$id = -1;
	} else {
		$id = $_GET["id"];
	}
    $id = intval($id);
	$row = new RowManager($tableName, $keyField->getName(), $id);
	$fieldset->addRowManager($row);

    $form->addFieldset($fieldset);

    //----TABLE 2----
    $fields = array();
    $keyField2 = new Hidden("ID", "", null, false);
    $fields[] = $keyField2;
    $fields[] = new ForeignKey("table1ID", "", $keyField, false);
    //$fields[] = new Text(dbTitle, formTitle, options, showInListView?, required?);

    $tableName = "";
    $row = new RowManager($tableName, $keyField2->getName());
    if($id == -1) {
        $filter = new SingleFilter($keyField->getName(), 0);
    } else {
        $filter = new SingleFilter($keyField->getName(), $id);
    }
    $row->addFilter($filter);

    $form->addFieldsets(Fieldset_Horizontal::generate($row, $fields, $form, num_blank_rows));

	//CREATE FORM
    $form->process();

	//INCLUDE HEADER FILE
	require_once($path."header.php");

	//CREATE LIST
	if(empty($_GET["id"]) && $mode != Form::ADD) {
		print $list->generateList($fieldset, $keyField, $linkField, $QS);
	} else {
		$form->display(true);
	}

	//INCLUDE FOOTER FILE
	require_once($path."footer.php");
?>
