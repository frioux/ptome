<?php
    $path = "./";
    $pageTitle = "User & System Management";
    require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
    require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
    require_once($path."OpenSiteAdmin/scripts/classes/Hook.php");
    require_once($path."OpenSiteAdmin/scripts/classes/ListManager.php");
    require_once($path."admin/scripts/LETUEmailField.php");
    $securityManager = new SecurityManager();

    function getSemesters() {
        $year = date("Y");
        $ret[(string)($year+1.75)] = "Fall ".($year+1);
        $ret[(string)($year+1.5)] = "Summer ".($year+1);
        $ret[(string)($year+1.25)] = "Spring ".($year+1);
        $ret[(string)($year+0.75)] = "Fall $year";
        $ret[(string)($year+0.5)] = "Summer $year";
        $ret[(string)($year+0.25)] = "Spring $year";
        $ret[(string)($year-0.25)] = "Fall ".($year-1);
        $ret[(string)($year-0.5)] = "Summer ".($year-1);
        $ret[(string)($year-0.75)] = "Spring ".($year-1);
        return $ret;
    }

    require_once($path."header.php");
?>

<h1>User and System Management</h1>
<h3>Semester Preferences</h3>
<?php
    $form = new Form(Form::EDIT, $_SERVER["SCRIPT_NAME"]);
    $fieldset = new Fieldset_Vertical($form->getFormType());
    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $field = $fieldset->addField(new Select("semester", "Your Current Semester", getSemesters(), false));

    class SemesterUpdateHook implements Hook {
        protected $keyField;
        function __construct(Field $keyField) {
            $this->keyField = $keyField;
        }

        public function process() {
            $_SESSION["semester"] = $this->keyField->getValue();
			return true;
        }
    }
    $row = new RowManager("users", $keyField->getName(), $_SESSION["ID"]);
	$fieldset->addRowManager($row);
    $form->addFieldset($fieldset);
    $form->process(array(new SemesterUpdateHook($field)));
    $form->setSubmitText("Change");
    $form->display();
?>
<?php
    if($securityManager->isPageVisible("editSemester")) {
        print '<h3>Semester Setting</h3>';
        $form = new Form(Form::EDIT, $_SERVER["SCRIPT_NAME"]);
        $fieldset = new Fieldset_Vertical($form->getFormType());
        $field = $fieldset->addField(new Select("semester", "Global Current Semester", getSemesters(), false));

        $row = new RowManager("users", "ID");
        foreach($row->getRowManagers() as $val) {
            $fieldset->addRowManager($val);
        }
        $form->addFieldset($fieldset);
        $form->process(array(new SemesterUpdateHook($field)));
        $form->setSubmitText("Change");
        $form->display();
    }
?>
<a name="users"></a>
<h3>User Preferences</h3>
<?php
	$mode = Form::EDIT;
    $form = new Form($mode, $_SERVER["SCRIPT_NAME"]);
    $form->setSubmitText("Update");

    $fieldset = new Fieldset_Vertical($form->getFormType());
    $levelArray[1] = "Developer";
    $levelArray[2] = "Administrator";
    $levelArray[3] = "TOMEKeeper";
    //prevent privilege escalation here
    $levels = array_slice($levelArray, $_SESSION["permissions"]-1, count($levelArray), true);
    $result = DatabaseManager::checkError("select * from `libraries`");
    $libraries = array();
    while($row = DatabaseManager::fetchAssoc($result)) {
        $libraries[$row["ID"]] = $row["name"];
    }

    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $fields[] = new Password("password", "Password", null, false);
    $fields[] = new LETUEmailField("email", "Email", array("maxlength"=>50), true, true);
    $fields[] = new Select("permissions", "Permissions", $levels, true, true);
    $fields[] = new Text("name", "Full Name", array("maxlength"=>50), true, false);
    $fields[] = new Text("secondContact", "Second Contact", array("maxlength"=>50), false, false);
    $fields[] = new Checkbox("notifications", "Notifications", null, false, false);

	$linkField = new Text("username", "Username", array("maxlength"=>20), true, true);
	array_unshift($fields, $linkField);
	$fields[] = new Checkbox("active", "Active", null, true, false);
	$fieldset->addFields($fields);
	$libField = $fieldset->addField(new Select("libraryID", "Library", $libraries, true, true));

	class LibraryUpdateHook implements Hook {
		protected $field;
		function __construct(Field $field) {
			$this->field = $field;
		}

		public function process() {
			$_SESSION["libraryID"] = $this->field->getValue();
			return true;
		}
	}

	if(!isset($_GET["id"]) || empty($_GET["id"])) {
		$id = -1;
	} else {
		$id = intval($_GET["id"]);
	}
	$row = new RowManager("users", $keyField->getName(), $id);
	$fieldset->addRowManager($row);
	$form->addFieldset($fieldset);
	$hooks = array();
	if($id == $_SESSION["ID"]) {
		$hooks[] = new LibraryUpdateHook($libField);
	}
	//hacks
	if($_REQUEST["submit"] != "Delete User") {
		$form->process($hooks);
	}

	$deleteForm = new Form(Form::DELETE, $_SERVER["SCRIPT_NAME"]);
	$deleteForm->setSubmitText("Delete User");
	$deleteFieldset = new Fieldset_Vertical($deleteForm->getFormType());
	$deleteFieldset->addField($keyField);
	$deleteFieldset->addRowManager($row);
	$deleteForm->addFieldset($deleteFieldset);
	$deleteForm->process();

	$list = new ListManager();
	if((empty($_GET["id"]) && $mode != Form::ADD) || (!empty($_GET["id"]) && !$form->selected())) {
		if(!$securityManager->isPageVisible("editUser")) {
			class LibraryFilterHook {
				protected $libraryID;
				function __construct($libraryID) {
					$this->libraryID = $libraryID;
				}

				public function process($entry) {
					//if the user can't edit users, they can still manage their own library (or at least the people in it with permissions at or below their level)
					return $entry["libraryID"] == $this->libraryID && $entry["permissions"] >= $_SESSION["permissions"];
				}
			}
			$list->addFilterHook(new LibraryFilterHook($_SESSION["libraryID"]));
		}
		print $list->generateList($fieldset, $keyField, $linkField, $form->getQS()."#users");
	} else {
		$form->display();

		if($_SESSION["ID"] != $id) {
			//if you can see them, you can remove them. Provided you are not them, of course
			$deleteForm->display();
		}
	}
?>
<a name="adduser"></a>
<h3>Add User</h3>
<?php
	$form = new Form(Form::ADD, $_SERVER["SCRIPT_NAME"]."#adduser", "#adduser");

	$fieldset = new Fieldset_Vertical($form->getFormType());
	//prevent privilege escalation here
	$levels = array_slice($levelArray, $_SESSION["permissions"]-1, count($levelArray), true);
	$result = DatabaseManager::checkError("select * from `libraries`");
	$libraries = array();
	while($row = DatabaseManager::fetchAssoc($result)) {
		$libraries[$row["ID"]] = $row["name"];
	}

	$keyField = $fieldset->addField(new Hidden("ID", "", null, false));
	$linkField = $fieldset->addField(new Text("username", "Username", array("maxlength"=>20), true, true));
	$fieldset->addField(new Select("permissions", "Permissions", $levels, true, true));
	if($securityManager->isPageVisible("addUser")) {
		$fieldset->addField(new Select("libraryID", "Library", $libraries, true, true));
	} else {
		$fieldset->addField(new Label("libraryID", "Library", $libraries[$_SESSION["libraryID"]], true, true));
	}
	$fieldset->addField(new Password("password", "Password", null, false, true));
	$fieldset->addField(new LETUEmailField("email", "Email", array("maxlength"=>50), true, false));
	$fieldset->addField(new Text("name", "Full Name", array("maxlength"=>50), true, false));
	$fieldset->addField(new Text("secondContact", "Second Contact", array("maxlength"=>50), false, false));
	$fieldset->addField(new Checkbox("notifications", "Notifications", null, false, false));
	$fieldset->addField(new Checkbox("active", "Active", null, true, false), 1);
	$fieldset->addField(new Hidden("semester", "", null, true, true), $_SESSION["semester"]);

	$row = new RowManager("users", $keyField->getName());
	$fieldset->addRowManager($row);
	$form->addFieldset($fieldset);
	$form->process();
	$form->display();
?>
<?php if($securityManager->isPageVisible("editLibraries")) { ?>
    <a name="library">
    <h3>Library Management</h3>
    <?php
		$mode = Form::EDIT;
        $form = new Form($mode, $_SERVER["SCRIPT_NAME"]);
        $fieldset = new Fieldset_Vertical($form->getFormType());

        $keyField = $fieldset->addField(new Label("ID", "ID", null, false));
        $linkField = $fieldset->addField(new Text("name", "Name", array("maxlength"=>100), true, true));
        $fieldset->addField(new Checkbox("interTOME", "InterTOME", null, true, false));

        if(!isset($_GET["id"]) || empty($_GET["id"])) {
            $id = -1;
        } else {
            $id = $_GET["id"];
        }
        $row = new RowManager("libraries", $keyField->getName(), $id);
        $fieldset->addRowManager($row);
        $form->addFieldset($fieldset);
        $form->process();

        $list = new ListManager();
        if((empty($_GET["id"]) && $mode != Form::ADD) || (!empty($_GET["id"]) && !$form->selected())) {
            print $list->generateList($fieldset, $keyField, $linkField, $form->getQS()."#library");
        } else {
            $form->display();
        }
    }
?>
<?php if($securityManager->isPageVisible("addLibraries")) { ?>
    <h3>Add Library</h3>
    <?php
        $form = new Form(Form::ADD, $_SERVER["SCRIPT_NAME"]);
        $fieldset = new Fieldset_Vertical($form->getFormType());

        $keyField = $fieldset->addField(new Hidden("ID", "", null, true));
        $linkField = $fieldset->addField(new Text("name", "Name", array("maxlength"=>100), true, true));

        $row = new RowManager("libraries", $keyField->getName());
        $fieldset->addRowManager($row);
        $form->addFieldset($fieldset);
        $form->process();
        $form->display();
    }
?>
<?php require_once($path."footer.php"); ?>
