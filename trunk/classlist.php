<?php
   $path = "./";
   $pageTitle = "Class List";
   require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");
   require_once($path."header.php");

   $querry = "SELECT class, name, ID
              FROM classes;";

   $resultSet = DatabaseManager::checkError($querry);
?>
 <h1>Class List</h1>

<table class="sortable"><thead><tr><th>Course Number</th><th>Course Name</th></tr></thead><tbody>

<?php
   while($row = DatabaseManager::fetchArray($resultSet))
   {
      $classURL = "viewClass.php?id=$row[2]";
      print "<tr>
               <td><a href=$path$classURL>$row[0]</td>
               <td><a href=$path$classURL>$row[1]</td>
            </tr>";
   }
?>

</tbody></table>

<?php require_once($path."footer.php"); ?>
