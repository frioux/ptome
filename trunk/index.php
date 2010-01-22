<?php
    $path = "./";
    $pageTitle = "Home";
    require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");
    require_once($path."header.php");
?>
<h1>Home</h1>

<script type="text/javascript">
function copyFirstAutocompleteValue(autoCompleteID, targetID) {
    if($(autoCompleteID).children[0].children[0] != undefined) {
        id = $(autoCompleteID).children[0].children[0].children[0].getAttribute("id");
        $(targetID).value = id;
    } else {
        $(targetID).value = 0;
    }
}
</script>

<table class="full noborder">
    <tr>
        <td class="center">
    <form action="viewClass.php" method="get" id="class_form">
        <table class="full noborder">
            <thead>
                <tr>
                    <th colspan="2">View Class</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>
                        <input type="hidden" name="id" id="classID" value="">
                        <input id="class" name="class" type="text" style="width:100%;" />
                        <div class="auto_complete" id="class_auto_complete"></div>
                        <script type="text/javascript">
                            <!--
                            function classCallback(element, entry) {
                                document.getElementById("classID").setAttribute("value", entry.children[0].getAttribute("id"));
                            }
                            new Ajax.Autocompleter( 'class', 'class_auto_complete', 'ajaxClass.php', {frequency:0.2, minChars:3, afterUpdateElement:classCallback} )
                            //-->
                        </script>
                    </td>
                    <td class="submit">
                        <input type="submit" value="Go" onClick="return(copyFirstAutocompleteValue('class_auto_complete', 'classID'));" />
                    </td>
                </tr>
            </tbody>
        </table>
    </form>
        </td>
        <td>
    <form action="isbninfo.php" method="get" id="isbn_form">
        <table class="full noborder">
            <thead>
                <tr>
                    <th colspan="2">View Book</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>
                        <input type="hidden" name="id" id="isbnID" value="">
                        <input id="isbn" name="isbn" type="text" style="width:100%;" />
                        <div class="auto_complete" id="isbn_auto_complete"></div>
                        <script type="text/javascript">
                            <!--
                            function isbnCallback(element, entry) {
                                document.getElementById("isbnID").setAttribute("value", entry.children[0].getAttribute("id"));
                            }
                            new Ajax.Autocompleter( 'isbn', 'isbn_auto_complete', 'ajaxBook.php', {frequency:0.2, minChars:3, afterUpdateElement:isbnCallback} )
                            //-->
                        </script>
                    </td>
                    <td class="submit">
                        <input type="submit" value="Go" onClick="return(copyFirstAutocompleteValue('isbn_auto_complete', 'isbnID'));">
                    </td>
                </tr>
            </tbody>
        </table>
    </form>
        </td>
        <td>
    <form action="viewPatron.php" method="get" id="patron_form">
        <table class="full noborder">
            <thead>
                <tr>
                    <th colspan="2" class="submit">Edit Patron</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>
                        <input type="hidden" name="id" id="patronID" value="">
                        <input id="patron" name="patron" type="text" value="" style="width:100%;" />
                        <div class="auto_complete" id="patron_auto_complete"></div>
                        <script type="text/javascript">
                            <!--
                            function patronCallback(element, entry) {
                                document.getElementById("patronID").setAttribute("value", entry.children[0].getAttribute("id"));
                            }
                            new Ajax.Autocompleter( 'patron', 'patron_auto_complete', 'ajaxPatron.php', {frequency:0.2, minChars:3, afterUpdateElement:patronCallback} )
                            //-->
                        </script>
                    </td>
                    <td class="submit">
                        <input type="submit" value="Go" onClick="return(copyFirstAutocompleteValue('patron_auto_complete', 'patronID'));" />
                    </td>
                </tr>
            </tbody>
        </table>
    </form>
        </td>
    </tr>
</table>
<?php require_once($path."footer.php"); ?>
