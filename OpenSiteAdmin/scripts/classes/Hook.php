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
	
    
    /**
	 * Defines an interface for creating hooks into the processing system.
	 * 
	 * @abstract
	 * @author John Oren
	 * @version 1.0 July 31, 2008
	 */
	interface hook {
        /**
         * Initiates custom processing for this hook.
         *
         * @return VOID
         */
		function process();
	}
