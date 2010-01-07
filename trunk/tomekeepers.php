<?php
   $path = "./";
   $pageTitle = "TOMEKeepers";
   require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");
   require_once($path."header.php");

   $querry = "SELECT users.username, users.name, users.email, libraries.name, users.secondContact
              FROM users, libraries
              WHERE (users.libraryID = libraries.ID)
              AND users.active = 1;";

   $resultSet = DatabaseManager::checkError($querry);
?>

<h1>TOMEKeepers</h1>

<table class="sortable">
   <thead>
      <tr>
         <th>
            User
         </th>
         <th>
            Name
         </th>
         <th>
            Email
         </th>
         <th>
            2nd Contact
         </th>
         <th>
            Library
         </th>
      </tr>
    </thead>
    <tbody>

    <?php
       while($row = mysqli_fetch_row($resultSet))
       {
          print "<tr><td>$row[0]</td><td>$row[1]</td><td>$row[2]</td><td>$row[4]</td><td>$row[3]</td></tr>";
       }
    ?>

   </tbody>
</table>
<br />

<strong>Email List:</strong>
   <blockquote>

   <?php
      $querry = "SELECT users.email
                 FROM users
                 WHERE users.active = 1;";

      $resultSet = DatabaseManager::checkError($querry);

      $users = array();
      while($row = mysqli_fetch_row($resultSet))
      {
         if($row[0] == '')
            continue;
         $users[] = $row[0];
         print "$row[0], ";
      }
   ?>
   </blockquote>
<strong>Email List (Outlook remix):</strong>
   <blockquote>

      <?php
         foreach($users as $user)
         {
           print "$user; ";
         }
      ?>
   </blockquote>

<?php require_once($path."footer.php"); ?>
