<?php
    $path = "./";
    $pageTitle = "Useless Books";
    require_once($path."header.php");
    require_once($path."OpenSiteAdmin/scripts/classes/DatabaseManager.php");

    function countUniqueBooks($data) {
        for($i = 0, $count = 0; $i < count($data); $i++, $count++) {
            if($data[$i]["ID"] == $data[$i+1]["ID"]) {
                $i++;
            }
        }
        return $count;
    }

    //construct the library where clause
    if(isset($_REQUEST["libraries"])) {
        $where = "";
        foreach($_REQUEST["libraries"] as $id) {
            if(empty($where)) {
                $where .= "and (`books`.`libraryID` = '".$id."'";
            }
            $where .= "or `books`.`libraryID` = '".$id."'";
        }
        $where .= ")";
    } else {
        $where = "and `books`.`libraryID` = '".$_SESSION["libraryID"]."'";
    }
    $sql = "SELECT `bookTypes`.`title` , `bookTypes`.`author` , `bookTypes`.`edition` , `bookTypes`.`isbn10` , `bookTypes`.`isbn13` , `books`.`ID` , `books`.`usable` , `books`.`donatorID` , `classes`.`class` , `classes`.`name` as `course`, `classes`.`ID` as `classID`, `borrowers`.`name`
            FROM `bookTypes`
            JOIN `books` ON `books`.`bookID` = `bookTypes`.`ID`
            JOIN `classbooks` ON `classbooks`.`bookID` = `bookTypes`.`ID`
            JOIN `classes` ON `classbooks`.`classID` = `classes`.`ID`
            JOIN `borrowers` ON `borrowers`.`ID` = `books`.`donatorID`
            WHERE `books`.`usable` = '0'
            AND `books`.`expired` = '0'
            ".$where."
            AND `classbooks`.`usable` = '1'
            ORDER BY `books`.`ID`";
    $data = DatabaseManager::fetchAssocArray($sql);

    $sql = "select * from `libraries`";
    $libraries = DatabaseManager::fetchAssocArray($sql);
?>
<h1>Useless Books</h1>
<h3>These books have a class associated with them, but are marked as not being usable:</h3>
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
                    <input value="Find Useless" type="submit">
                </td>
            </tr>
        </tbody>
    </table>
</form>
<p>
   <?php
      $count = countUniqueBooks($data);
      if($count == 1){
         $text = "book";
      } else {
         $text = "books";
      }
      print "$count useless $text found";
      ?>
   </p>
<p></p>
<table id="sortable-table-0" class="sortable">
    <thead>
        <tr>
            <th class="sortcol">
                ID
            </th>
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
                Originator
            </th>
            <th class="sortcol">
                Classes
            </th>
        </tr>
    </thead>
    <tbody>
        <?php
        for($i = 0; $i < count($data); $i++) {
            $row = $data[$i];
            ?>
            <tr>
                <td>
                    <a href="bookinfo.php?id=<?php print $row["ID"]; ?>"><?php print $row["ID"]; ?></a>
                </td>
                <td>
                    <?php print $row["title"]; ?>
                </td>
                <td>
                    <?php print $row["author"]; ?>
                </td>
                <td>
                    <?php print $row["edition"]; ?>
                </td>
                <td>
                    <a href="/viewPatron.php?id=<?php print $row["donatorID"]; ?>"><?php print $row["name"]; ?></a>
                </td>
                <td>
                    <?php
                        print '<a href="/viewClass.php?id='.$row["classID"].'">'.$row["class"].'</a> - '.$row["course"];
                        while($data[$i+1]["ID"] == $row["ID"]) {
                            $row = $data[++$i];
                            print '<br>';
                            print '<a href="/viewClass.php?id='.$row["classID"].'">'.$row["class"].'</a> - '.$row["course"];
                        }
                    ?>
                </td>
            </tr>
        <?php } ?>
    </tbody>
</table>
<?php require_once($path."footer.php"); ?>
