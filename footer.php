</div><!-- end body -->
<div id="footer">
  <a href="<?php print $path; ?>addClass.php">Add Class</a> |
  <a href="<?php print $path; ?>orphans.php">Orphans</a> |
  <a href="<?php print $path; ?>uselessBooks.php">Useless</a> |
  <a href="<?php print $path; ?>stats.php">Stats</a> |
  <a href="<?php print $path; ?>inventory.php">Inventory</a> |
  <a href="<?php print $path; ?>guide.php">TOME Guide</a> |
  <a href="<?php print $path; ?>management.php">User and System Management</a>

</div>
</div><!-- end container -->
</div><!-- end atmosphere -->
<?php if(isset($_SESSION["username"]) && $_SESSION["permissions"] <= 2) { ?>
    <div style="position:absolute; top:10px; left:-30px; width:150px;">
        <a href="<?php print $path; ?>admin/index.php">Admin Panel</a>
    </div>
<?php } ?>
</body>
</html>
<?php ob_end_flush(); ?>
