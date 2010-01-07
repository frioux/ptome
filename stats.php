<?php
   $path = "./";
   $pageTitle = "Statistics";
   require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");
   require_once($path."header.php");

   $currentSemester = $_SESSION['semester'];


    $sql = "select * from `libraries`";
    $result = DatabaseManager::checkError($sql);
    while($row = mysqli_fetch_assoc($result)) {
        $libraries[] = $row;
    }

?>
<h1>Statistics</h1>

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
   $row = mysqli_fetch_row($resultSet);
   $totalBooks = $row[0];

   $query = "SELECT count(*)
             FROM books
             WHERE ($where) AND books.expired = 0;";

   $resultSet = DatabaseManager::checkError($query);
   $row = mysqli_fetch_row($resultSet);
   $currentBooks = $row[0];

   $query = "SELECT count(*)
             FROM checkouts 
             WHERE ($whereCheckouts);";

   $resultSet = DatabaseManager::checkError($query);
   $row = mysqli_fetch_row($resultSet);
   $totalCheckouts = $row[0];

   $query = "SELECT count(*)
             FROM checkouts 
             WHERE ($whereCheckouts)
             AND checkouts.semester = $currentSemester;";

   $resultSet = DatabaseManager::checkError($query);
   $row = mysqli_fetch_row($resultSet);
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
   $topCount = mysqli_num_rows($resultSet);

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
      $row = mysqli_fetch_row($resultSet);
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
