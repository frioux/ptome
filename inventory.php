<?php
   $path = "./";
   $pageTitle = "Library Inventory";
   require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");
   require_once($path."header.php");

   $libraryID = $_SESSION['libraryID'];

   $query = "SELECT books.ID, bookTypes.title, bookTypes.author, bookTypes.edition,
                bookTypes.isbn10, bookTypes.isbn13, bookTypes.ID
             FROM books, bookTypes
             WHERE (books.libraryID = $libraryID AND books.bookID = bookTypes.ID AND books.expired=0);";

   $resultSet = DatabaseManager::checkError($query);
   $count = DatabaseManager::getNumResults($resultSet);
?>

<h1>Library Inventory</h1>
<h3>These books should be in your library somwhere (<?php echo $count ?>)</h3>

<table class="sortable">
   <thead>
      <tr>
         <th>Title</td>
         <th>Author</td>
         <th>Edition</td>
         <th>ISBN</td>
         <th>ID</td>
      </tr>
   </thead>
   <tbody>

   <?php
      while($row = DatabaseManager::fetchArray($resultSet))
      {
         $bookURL = "bookinfo.php?id=$row[0]";
         $isbnURL = "isbninfo.php?id=$row[6]";
         if($row[4] != null)
         {
            print "<tr>
                      <td>$row[1]</td>
                      <td>$row[2]</td>
                      <td>$row[3]</td>
                      <td><a href=$path$isbnURL>$row[4]</a></td>
                      <td><a href=$path$bookURL>$row[0]</a></td>
                   </tr>";
         } else {
            print "<tr>
                     <td>$row[1]</td>
                     <td>$row[2]</td>
                     <td>$row[3]</td>
                     <td><a href=$path$isbnURL>$row[5]</a></td>
                     <td><a href=$path$bookURL>$row[0]</a></td>
                   </tr>";
         }
      }
   ?>

   </tbody>
</table>

<?php require_once($path."footer.php"); ?>
