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
	
	
	session_start();
	//destroy session data
	$_SESSION = array();
	//delete cookies
	if(isset($_COOKIE["username"])) {
		setcookie( "username", "", time()-(60*60*24*365), "/", SITE_NAME);
		setcookie( "password", "", time()-(60*60*24*365), "/", SITE_NAME);
	}
	//formally destroy the session
	session_destroy();
	
	//offer to log back in
	header("Location:../login.php");
?>
