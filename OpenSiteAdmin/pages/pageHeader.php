<?php
    //INCLUDE REQUIRED FILES
	require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");
	require_once($path."OpenSiteAdmin/scripts/classes/ListManager.php");
	require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
	require_once($path."OpenSiteAdmin/scripts/classes/RowManager.php");
	require_once($path."OpenSiteAdmin/scripts/classes/Field.php");
	require_once($path."OpenSiteAdmin/scripts/classes/Filter.php");

    $pageName = substr(basename($_SERVER['SCRIPT_NAME']), 6, -4);
    $QS = $_SERVER["QUERY_STRING"];
    $mode = $_GET["mode"];
    $modeStr = Form::getModeText($mode);

	$form = new Form($mode);
	$list = new ListManager();
	$securityManager = new SecurityManager($pageName, $modeStr);