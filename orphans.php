<?php
    $path = "./";
    $pageTitle = "Orphans";
    require_once($path."header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");

    $libraryID = $_SESSION['libraryID'];
    $username = $_SESSION['username'];

    $query = "SELECT DISTINCT bookTypes.title, bookTypes.author, bookTypes.edition,
                  bookTypes.isbn10, bookTypes.isbn13, books.ID, bookTypes.ID
              FROM (bookTypes LEFT JOIN classbooks ON bookTypes.ID = classbooks.bookID)
              LEFT JOIN books ON bookTypes.ID = books.bookID
              WHERE classbooks.bookID IS NULL
              AND books.libraryID = $libraryID
              AND books.expired = 0;";

   $resultSet = DatabaseManager::checkError($query);
   $count = DatabaseManager::getNumResults($resultSet);
?>
<h1>Orphan Books</h1>
<h3>These books have no class associated with them:</h3>
<p>
    <?php
       if($count == 0)
       {
          print "You rock $username!  No orphans found!";
       }
       else
          if($count == 1){
             $text = "orphan";
          } else {
             $text = "orphans";
          }
            echo "$count $text found.";
    ?>
</p>
<table id="sortable-table-0" class="sortable full">
    <thead>
        <tr>
            <th class="sortcol">
                Title
            </th>
            <th class="sortcol">
                Author
            </th>
            <th class="sortcol">
                Edition
            </th>
            <th class="sortcol">
                ISBN
            </th>
            <th class="sortcol">
                ID
            </th>
        </tr>
    </thead>
    <tbody>
    <?php
      while($row = DatabaseManager::fetchArray($resultSet))
      {
         $bookURL = "bookinfo.php?id=$row[5]";
         $isbnURL = "isbninfo.php?id=$row[6]";
         if($row[3] != null)
         {
            print "<tr>
                      <td>$row[0]</td>
                      <td>$row[1]</td>
                      <td>$row[2]</td>
                      <td><a href=$path$isbnURL>$row[3]</a></td>
                      <td><a href=$path$bookURL>$row[5]</a></td>
                   </tr>";
         } else {
            print "<tr>
                       <td>$row[0]</td>
                       <td>$row[1]</td>
                       <td>$row[2]</td>
                       <td><a href=$path$isbnURL>$row[4]</a></td>
                       <td><a href=$path$bookURL>$row[5]</a></td>
                   </tr>";
         }
      }
      ?>
    </tbody>
</table>
<?php require_once($path."footer.php"); ?>
