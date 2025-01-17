<?php
    if(session_id() === "")
	{
		session_start();
	}

    //start output buffering
    ob_start();
    if(!isset($page)) {
        $page = "index";
    }
    require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");
    new SecurityManager($page);

    function getSemesterName($semester, $fromDateTime=false) {
        if($fromDateTime) {
            $time = strtotime($semester);
            $year = date("Y", $time);
            $tmp = date("n", $time);
            if($tmp <= 5) {
                $ret = "Spring";
            } elseif($tmp <= 8) {
                $ret = "Summer";
            } else {
                $ret = "Fall";
            }
        } else {
            $tmp = explode(".", $semester);
            $year = $tmp[0];
            if($tmp[1] == 75) {
                $ret = "Fall";
            } elseif($tmp[1] == 5) {
                $ret = "Summer";
            } else {
                $ret = "Spring";
            }
        }
        return $year.", ".$ret;
    }

    function dateFromMySQL($date) {
        $time = strtotime($date);
        return date("F j, Y", $time)." at ".date("h:i:s A", $time);
    }

    $username = $_SESSION["username"];
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>TOME - <?php echo $pageTitle; ?></title>
    <script src="<?php print $path; ?>layout/prototype.js" type="text/javascript"></script>
    <script src="<?php print $path; ?>layout/fastinit.js" type="text/javascript"></script>
    <script src="<?php print $path; ?>layout/scriptaculous.js" type="text/javascript"></script>
    <script src="<?php print $path; ?>layout/tablesort.js" type="text/javascript"></script>
    <script src="<?php print $path; ?>layout/datepickercontrol.js" type="text/javascript"></script>
    <script type="text/javascript">
        function copyFirstAutocompleteValue(data) {
            for(i=0; i < data.length; i+=2) {
                if($(data[i+1]).value == undefined) {
                    if($(data[i]).children[0].children[0] != undefined) {
                        id = $(data[i]).children[0].children[0].children[0].getAttribute("id");
                        $(data[i+1]).value = id;
                    } else {
                        $(data[i+1]).value = 0;
                    }
                }
            }
        }
    </script>

    <link href="<?php print $path; ?>layout/datepickercontrol.css" type="text/css" rel="stylesheet">
    <link href="<?php print $path; ?>layout/screen.css" media="screen,projection" rel="stylesheet" type="text/css" />
    <link href="<?php print $path; ?>layout/print.css" media="print" rel="stylesheet" type="text/css" />
    <link rel="icon" href="<?php print $path; ?>images/favicon.ico" type="image/x-icon" />
    <link rel="shortcut icon" href="<?php print $path; ?>favicon.ico" type="image/x-icon" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body class="yui-skin-sam">
  <div id="atmosphere">
  <div id="statusbarleft">
    <a href="<?php print $path; ?>admin/pages/contact.php">Need help?</a>
  </div>
  <div id="statusbar">
    <?php
        if(isset($_SESSION["username"]) && $_SESSION["permissions"] <= 1) {
            $buildTime = `svn info | grep "Last Changed Rev" | awk -F' ' '{print $4}'`;
            print "Revision [[BUILD_TIME]] ";
        }
    ?>
    Logged in as: <?php print $username; ?> | <a href="<?php print $path; ?>admin/logout.php">Logout</a>
  </div>

  <div id="container">
    <div id="header">
      <div id="banner">
        <a href="<?php print $path; ?>">
          <h1 id="logo">&nbsp;</h1>
        </a>
        <dl id="status">
          <dt>Current semester</dt>
          <dd><?php print getSemesterName($_SESSION["semester"]); ?></dd>
        </dl><!-- end status -->
      </div><!-- end banner -->
      <div id="navigation">
        <ul>
          <li><a href="<?php print $path; ?>">Home</a></li>
          <li><a href="<?php print $path; ?>addtomebook.php">Add TOME Book</a></li>
          <li><a href="<?php print $path; ?>report.php">Semester Report</a></li>
          <li><a href="<?php print $path; ?>tomekeepers.php">Tomekeepers</a></li>
          <li><a href="<?php print $path; ?>classlist.php">Class List</a></li>
          <li><form method="get" action="<?php print $path; ?>bookinfo.php">
          Book ID: <input type="text" size="4" name="id"/> <input type="submit" value="Search" /></form></li>
        </ul>
      </div><!-- end navigation -->
    </div><!-- end header -->

    <div id="body">
