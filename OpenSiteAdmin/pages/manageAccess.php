<?php
	/*
	 *	Copyright 2007 John Oren
	 *
	 *	Licensed under the Apache License, Version 2.0 (the "License");
	 *	you may not use this file except in compliance with the License.
	 *	You may obtain a copy of the License at
	 *		http://www.apache.org/licenses/LICENSE-2.0
	 *	Unless required by applicable law or agreed to in writing, software
	 *	distributed under the License is distributed on an "AS IS" BASIS,
	 *	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 *	See the License for the specific language governing permissions and
	 *	limitations under the License.
	 */


	$path = "../../";
	require_once($path."OpenSiteAdmin/pages/pageHeader.php");

	//SECURITY CHECKING \ REDIRECT CHECKS

	//FUNCTION DEFINITIONS

	//BEGIN TABLE DEFINITION
	$fieldset = new Fieldset_Vertical($form->getFormType());

	$levels[1] = "Developers";
    $levels[2] = "Admin";
	$levels[3] = "TOME Keepers";

	$keyField = $fieldset->addField(new Hidden("ID", "", null, false));
	$linkField = $fieldset->addField(new Text("pageName", "Page", array("maxlength"=>50), true, true));
	$fieldset->addField(new Select("minLevel", "Minimum Level", $levels, true, true))->setDefaultValue(2);
	$fieldset->addField(new Text("message", "Access Restricted Message", array("maxlength"=>255), true));
	//set a default value for this select block
	//-- end table definition

	$tableName = "access";
    //if no ID has been defined, set the default none value
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
    if($mode == Form::ADD) {
        $n = $linkField->getFieldName();
        //create the default addFoo, editFoo, and deleteFoo authorization
        //categories for the given page name (foo)
        if(isset($_POST[$n])) {
            $name = ucfirst($_POST[$n]);
            $_POST[$n] = "add".$name;
            $form->process(array(false));
            $_POST[$n] = "edit".$name;
            $form->process(array(false));
            $_POST[$n] = "delete".$name;
        }
    }
    $form->process();

	//INCLUDE HEADER FILE
	require_once($path."header.php");

	//CREATE LIST
	if(empty($_GET["id"]) && $mode != Form::ADD) {
		print $list->generateList($fieldset, $keyField, $linkField, $QS);
	} else {
?>
The admin page is a special designation that should not be renamed. Changing the access level of admin changes the access level for the entire administrative system.
<br>
<br>
The index page is a special designation that should not be renamed. It is reserved for pages that should always be available to anyone with valid login credentials for the site,
such as the main index page, which is used for displaying error messages and access restriction messages.
<br>
<?php
		$form->display();
	}

	//INCLUDE FOOTER FILE
	require_once($path."footer.php");
?>
