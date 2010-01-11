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
<a name="users">
<h3>User Preferences</h3>
<?php
    $form = new Form(Form::EDIT, $_SERVER["SCRIPT_NAME"]);
    $form->setSubmitText("Update");

    $fieldset = new Fieldset_Vertical($form->getFormType());
    $levels[1] = "Developer";
    $levels[2] = "Administrator";
    $levels[3] = "TOMEKeeper";
    //prevent privilege escalation here
    $levels = array_slice($levels, $_SESSION["permissions"]-1, count($levels), true);
    $result = DatabaseManager::checkError("select * from `libraries`");
    $libraries = array();
    while($row = DatabaseManager::fetchAssoc($result)) {
        $libraries[$row["ID"]] = $row["name"];
    }

    $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
    $fields[] = new Password("password", "Password", null, false);
    $fields[] = new LETUEmailField("email", "Email", array("maxlength"=>50), true, true);
    $fields[] = new Select("permissions", "Permissions", $levels, true, true);
    $fields[] = new Text("name", "Full Name", array("maxlength"=>50), true, true);
    $fields[] = new Text("secondContact", "Second Contact", array("maxlength"=>50), false, true);
    $fields[] = new Checkbox("notifications", "Notifications", null, false, false);

    if($securityManager->isPageVisible("editUser")) {
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
            }
        }

        if(!isset($_GET["id"]) || empty($_GET["id"])) {
            $id = -1;
        } else {
            $id = $_GET["id"];
        }
        $row = new RowManager("users", $keyField->getName(), $id);
        $fieldset->addRowManager($row);
        $form->addFieldset($fieldset);
        $hooks = array();
        if($id = $_SESSION["ID"]) {
            $hooks[] = new LibraryUpdateHook($libField);
        }
        $form->process($hooks);

        $list = new ListManager();
        if((empty($_GET["id"]) && $mode != Form::ADD) || (!empty($_GET["id"]) && !$form->selected())) {
            print $list->generateList($fieldset, $keyField, $linkField, $form->getQS()."#users");
        } else {
            $form->display();
        }
    } else {
        array_unshift($fields, new Label("username", "Username", null, true, true));
        $fieldset->addFields($fields);
        $fieldset->addField(new Label("libraryID", "Library", $libraries[$_SESSION["libraryID"]], true, true));

        $id = $_SESSION["ID"];
        $row = new RowManager("users", $keyField->getName(), $id);
        $fieldset->addRowManager($row);
        $form->addFieldset($fieldset);
        $form->process();
        $form->display();
    }
?>
<?php
    if($securityManager->isPageVisible("addUser")) { ?>

         <a name="adduser"></a>
         <h3>Add User</h3>
     <?php
        $form = new Form(Form::ADD, $_SERVER["SCRIPT_NAME"]."#adduser");

        $fieldset = new Fieldset_Vertical($form->getFormType());
        //prevent privilege escalation here
        $levels = array_slice($levels, $_SESSION["permissions"]-1, count($levels), true);
        $result = DatabaseManager::checkError("select * from `libraries`");
        $libraries = array();
        while($row = DatabaseManager::fetchAssoc($result)) {
            $libraries[$row["ID"]] = $row["name"];
        }

        $keyField = $fieldset->addField(new Hidden("ID", "", null, false));
        $linkField = $fieldset->addField(new Text("username", "Username", array("maxlength"=>20), true, true));
        $fieldset->addField(new Select("permissions", "Permissions", $levels, true, true));
        $fieldset->addField(new Select("libraryID", "Library", $libraries, true, true));
        $fieldset->addField(new Password("password", "Password", null, false, true));
        $fieldset->addField(new LETUEmailField("email", "Email", array("maxlength"=>50), true, false));
        $fieldset->addField(new Text("name", "Full Name", array("maxlength"=>50), true, false));
        $fieldset->addField(new Text("secondContact", "Second Contact", array("maxlength"=>50), false, false));
        $fieldset->addField(new Checkbox("notifications", "Notifications", null, false, false));
        $fieldset->addField(new Checkbox("active", "Active", null, true, false), true);
        $fieldset->addField(new Hidden("semester", "", null, true, true), $_SESSION["semester"]);

        $row = new RowManager("users", $keyField->getName());
        $fieldset->addRowManager($row);
        $form->addFieldset($fieldset);
        $form->process();
        $form->display();
    }
?>
<?php if($securityManager->isPageVisible("editLibraries")) { ?>
    <a name="library">
    <h3>Library Management</h3>
    <?php
        $form = new Form(Form::EDIT, $_SERVER["SCRIPT_NAME"]);
        $fieldset = new Fieldset_Vertical($form->getFormType());

        $keyField = $fieldset->addField(new Label("ID", "ID", null, true));
        $linkField = $fieldset->addField(new Text("name", "Name", null, true, true));
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
        $linkField = $fieldset->addField(new Text("name", "Name", null, true, true));

        $row = new RowManager("libraries", $keyField->getName());
        $fieldset->addRowManager($row);
        $form->addFieldset($fieldset);
        $form->process();
        $form->display();
    }
?>
<?php require_once($path."footer.php"); ?>
