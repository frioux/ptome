<?php
   $path = "./";
   $pageTitle = "Statistics";
   require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");
   require_once($path."header.php");

   $currentSemester = $_SESSION['semester'];


    $sql = "select * from `libraries`";
    $libraries = DatabaseManager::fetchAssocArray($sql);
?>
<h1>Statistics</h1>

<b>Activity in the last 8 months</b>
<?php
    $sql = "SELECT libraries.name, COUNT(checkouts.ID) AS count FROM checkouts JOIN libraries ON libraries.ID=libraryFromID WHERE checkouts.out >= DATE_SUB(NOW(), INTERVAL 8 MONTH) GROUP BY checkouts.libraryFromID ORDER BY count DESC";
    $result = DatabaseManager::checkError($sql);
    $rowsFrom = DatabaseManager::fetchAssocArray($result);
    $totalFrom = 0;
    foreach($rowsFrom as $row) {
        $totalFrom += $row["count"];
    }
    $rows = array();
    foreach($rowsFrom as $row) {
        $rows[$row["name"]]["from"] = $row["count"];
    }

    $sql = "SELECT libraries.name, COUNT(checkouts.ID) AS count FROM checkouts JOIN libraries ON libraries.ID=libraryToID WHERE checkouts.out >= DATE_SUB(NOW(), INTERVAL 8 MONTH) GROUP BY checkouts.libraryToID ORDER BY count DESC";
    $result = DatabaseManager::checkError($sql);
    $rowsTo = DatabaseManager::fetchAssocArray($result);
    $totalTo = 0;
    foreach($rowsTo as $row) {
        $totalTo += $row["count"];
    }
    foreach($rowsTo as $row) {
        $rows[$row["name"]]["to"] = $row["count"];
    }

    function cmp($a, $b) {
        if(@$a["to"] == @$b["to"]) {
            return @$a["from"] < @$b["from"] ? 1 : -1;
        }
        return @$a["to"] < @$b["to"] ? 1 : -1;
    }
    uasort($rows, "cmp");

    print "<table>";
    print "<tr style='font-weight:bold;'><td>Floor</td><td># Checkouts to</td><td>% Checkouts to</td><td># Checkouts from</td><td>% Checkouts from</td></tr>";
    foreach($rows as $name=>$row) {
        print "<tr>";
        @print "<td style='font-weight:bold;'>".$name."</td><td>".$row["to"]."</td><td>".round($row["to"]/$totalTo*100)."%</td><td>".$row["from"]."</td><td>".round($row["from"]/$totalFrom*100)."%</td>";
        print "</tr>";
    }
    print "</table>";
?>
<br><br>

<form name="report" action="<?php print $_SERVER["SCRIPT_NAME"]; ?>" method="post">
    <table>
        <tbody>
            <tr>
                <td>
                    Libraries
                </td>
                <td>
                    <select id="libraries" name="libraries[]" size="5" multiple="multiple">
                        <?php
                            $i = 0;
                            foreach($libraries as $library) {
                                print '<option value="'.$library["ID"].'"';
                                if((!isset($_REQUEST["libraries"]) && $_SESSION["libraryID"] == $library["ID"]) || (isset($_REQUEST["libraries"]) && in_array($library["ID"], $_REQUEST["libraries"]))) {
                                    print " selected";
                                }
                                if($_SESSION["libraryID"] == $library["ID"]) {
                                    $id = $i;
                                }
                                print '>'.$library["name"].'</option>';
                                $i++;
                            }
                        ?>
                    </select>
                    <br>
                    <a href="#" onclick="$$('#libraries option').each( function(n) { n.selected=true;})">Select All</a> | <a href="#" onclick="$$('#libraries option').each( function(n) { n.selected=false;}); [<?php print $_SESSION["libraryID"]-1; ?>].each( function (n) { $('libraries').options[n].selected=true;})">Select Mine</a>
                </td>
            </tr>
            <tr>
                <td colspan="2" class="submit">
                    <input value="Update Stats" type="submit">
                </td>
            </tr>
        </tbody>
    </table>
</form>

<?php

   $libID = $_SESSION['libraryID'];
   $allLibraries = $_POST['libraries'];

   //Generate WHERE clauses
   $where = "";
   if($allLibraries == NULL)
   {
      $where = "books.libraryID = $libID";
      $whereCheckouts = "checkouts.libraryFromID = $libID";
   }
   else
   {
      foreach($allLibraries as $lib)
      {
         if(strlen($where) == 0)
         {
            $where = "books.libraryID = $lib";
            $whereCheckouts = "checkouts.libraryFromID = $lib";
         }
         else
         {
            $where .= " OR books.libraryID = $lib";
            $whereCheckouts .= " OR checkouts.libraryFromID = $lib";
         }
      }
   }

   $query = "SELECT count(*)
             FROM books
             WHERE ($where);";

   $resultSet = DatabaseManager::checkError($query);
   $row = DatabaseManager::fetchArray($resultSet);
   $totalBooks = $row[0];

   $query = "SELECT count(*)
             FROM books
             WHERE ($where) AND books.expired = 0;";

   $resultSet = DatabaseManager::checkError($query);
   $row = DatabaseManager::fetchArray($resultSet);
   $currentBooks = $row[0];

   $query = "SELECT count(*)
             FROM checkouts
             WHERE ($whereCheckouts);";

   $resultSet = DatabaseManager::checkError($query);
   $row = DatabaseManager::fetchArray($resultSet);
   $totalCheckouts = $row[0];

   $query = "SELECT count(*)
             FROM checkouts
             WHERE ($whereCheckouts)
             AND checkouts.semester = $currentSemester;";

   $resultSet = DatabaseManager::checkError($query);
   $row = DatabaseManager::fetchArray($resultSet);
   $semesterCheckouts = $row[0];
?>
<b>Total books in the database</b>: <?php echo $totalBooks ?><br />
<b>Books in the current collection</b>: <?php echo $currentBooks ?><br />
<b>Total Checkouts</b>: <?php echo $totalCheckouts ?><br />
<b>Checkouts for this semester</b>: <?php echo $semesterCheckouts ?><br />

<?php
   $query = "SELECT borrowers.name, COUNT(donatorID), borrowers.ID
             FROM books, borrowers
             WHERE books.donatorID = borrowers.ID
             AND ($where)
             GROUP BY donatorID
             ORDER BY COUNT(donatorID) DESC;";

   $resultSet = DatabaseManager::checkError($query);
   $topCount = DatabaseManager::getNumResults($resultSet);

   //Only displaying top 10 donors
   if($topCount > 10)
   {
      $topCount = 10;
   }
?>

<h3>Top <?php echo $topCount ?> Donators</h3>

<?php
   for($i = 1; $i <= 10; $i++)
   {
      $row = DatabaseManager::fetchArray($resultSet);
      if($row == NULL)
      {
         break;
      }
      $patronURL = "viewPatron.php?id=$row[2]";
      echo "#$i. <a href=$path$patronURL>$row[0]</a> - $row[1] <br />";
      $topCount++;
   }
?>

<?php require_once($path."footer.php"); ?>
