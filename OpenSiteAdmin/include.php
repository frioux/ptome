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

	//define site name constant (for creating and destroying cookies)
	define("SITE_NAME", "http://www.letuacm.org/tome/");
	//define site database constants
	if($_SERVER["HTTP_HOST"] == "www.".SITE_NAME || $_SERVER["HTTP_HOST"] == SITE_NAME) { //live
		define("DB_USER", "tome");
		define("DB_PASS", "-@V3j}qr4KP?");
		define("DB_ROOT", "localhost");
		define("DB_NAME", "TOME");
	} else { //dev
		define("DB_USER", "root");
		define("DB_PASS", "jimbo111");
		define("DB_ROOT", "localhost");
		define("DB_NAME", "TOME");
	}

    /**
     * useful debug function that displays variables or arrays in a pretty format.
     *
     * @param STRING $name Name of the array (for pretty display purposes).
     * @param MIXED $array Array of data, but if it isn't an array we try to print it by itself.
     * @return VOID
     */
	function dump($name, $array) {
		if(!is_array($array)) {
			print "\$".$name." = ".$array."<br>";
			return;
		}
		foreach($array as $key=>$val) {
			if(is_array($val)) {
				dump($name."[".$key."]", $val);
			} else {
				print $name."[".$key."] = ".$val."<br>";
			}
		}
	}
?>
