<?php
    $path = "./";
    $pageTitle = "Home";
    require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");
    require_once($path."header.php");
?>
<h1>Home</h1>

<div style="display:inline;float:left;margin:0 6px 6px 0;">
    <form action="viewClass.php" method="get" name="isbnview">
        <table>
            <thead>
                <tr>
                    <th colspan="3">
                        View Class
                    </th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>
                        Class
                    </td>
                    <td>
                        <input type="hidden" name="id" id="classID" value="">
                        <input id="class" name="class" type="text" />
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
                        <input type="submit" value="Go" />
                    </td>
                </tr>
            </tbody>
        </table>
    </form>
</div>

<div style="display:inline;float:left;margin:0 6px 6px 0;">
    <form action="isbninfo.php" method="get">
        <table>
            <thead>
                <tr>
                    <th colspan="3">
                        View Book
                    </th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>
                        Book
                    </td>
                    <td>
                        <input type="hidden" name="id" id="isbnID" value="">
                        <input id="isbn" name="isbn" type="text" />
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
                        <input type="submit" value="Go">
                    </td>
                </tr>
            </tbody>
        </table>
    </form>
</div>

<div style="display:inline;float:left;margin:0 0 6px 0;">
    <form action="viewPatron.php" method="get">
        <table>
            <thead>
                <tr>
                    <th colspan="3" class="submit">
                        Edit Patron
                    </th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>
                        Email
                    </td>
                    <td>
                        <input type="hidden" name="id" id="patronID" value="">
                        <input id="patron" name="patron" type="text" value="" />
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
                        <input type="submit" value="Go" />
                    </td>
                </tr>
            </tbody>
        </table>
    </form>
</div>
<div style="clear:both"></div>
<?php require_once($path."footer.php"); ?>
