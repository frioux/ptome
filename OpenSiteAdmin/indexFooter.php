<?php
	/*
	 *	Copyright 2007 John Oren
	 *
	 *	Licensed under the Apache License, Version 2.0 (the "License");
	 *	you may not use this file except in compliance with the License.
	 *	You may obtain a copy of the License at
	 *		http://www.apache.org/licenses/LICENSE-2.0
	 *	Unless required by applicable law or agreed to in writing, software
	 *	distributed under the License is distributed on an "AS IS" BASIS,
	 *	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 *	See the License for the specific language governing permissions and
	 *	limitations under the License.
	 */
?>
<a href="<?php print $path; ?>OpenSiteAdmin/pages/manageUser.php?mode=<?php print Form::EDIT; ?>&id=<?php print $_SESSION['ID']; ?>" style="text-decoration:none;">Update My Information</a>
<br>
<br>
<a href="<?php print $path; ?>admin/logout.php" style="text-decoration:none;">Logout</a>
<?php
	//END CUSTOM CODE

	//INCLUDE FOOTER FILE

	print '<br><br><br>
	<span style="text-align:center; font-size:11px;">
		Powered by <a href="http://www.sourceforge.net/projects/opensiteadmin/" target="_new">OpenSiteAdmin</a>
	</span>';
	require_once($path."footer.php");
?>
