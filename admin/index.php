<?php
    $path = "../";
    $pageTitle = "Administration";
    require_once($path."OpenSiteAdmin/indexHeader.php");

    addPage("libraries");
    addPage("tomekeepers");
    addPage("borrowers");
    addPage("classes");
    addPage("bookTypes");
    addPage("books");
?>

</table>
<br>
<br>

<?php require_once($path."OpenSiteAdmin/indexFooter.php"); ?>
