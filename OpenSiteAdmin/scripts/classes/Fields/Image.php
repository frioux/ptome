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
	 * Handles display and processing for an Image field.
	 *
	 * Allows an image to be uploaded, verifying the file extention, checking file size limitations,
	 * and ensuring that each database entry references a unique file (to facilitate cleanup when
	 * deleting entries without the overhead of a reference counter).
	 * $options["path"] - Full path (relative or absolute) to the directory to save uploaded images to.
	 * $options["ext"] - Comma delimited list of valid file extensions (3 or 4 letters maximum).
	 * $options["width"] - Width of the image shown as a preview of the uploaded image.
	 * $options["height"]- Height of the image shown as a preview of the uploaded image.
	 *
	 * @author John Oren
	 * @version 1.1 August 4, 2008
	 */
    class Image extends Field {
        /** @var 5mb maximum file size */
        protected static $maxSize = 5120000;

        /**
		 * Attempts to delete the given file.
		 *
		 * @param STRING $file The full name and path (relative or absolute) of the file to delete.
		 * @return VOID
		 */
		private function deleteFile($file) {
			if(file_exists($file)) {
				if(!unlink($file)) {
					ErrorLogManager::log("Unable to remove the file ".$file." with form field ".$this->getName(), ErrorLogManager::FATAL);
					$this->errorText = "Failed to remove the file - Contact your System Administrator<br>This error has been logged";
					return false;
				}
			}
			return true;
		}

		/**
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$options = $this->getOptions();
			$img = $this->getValue();
			if(!empty($img)) {
				$types = explode(",", $options["ext"]);
				if($this->isCorrectType($img, $types)) {
					$ret .= '<img src="'.$options["path"].$img.'" width="'.$options["width"].'" height="'.$options["height"].'"><br>';
				}
                $ret .= '<input type="hidden" name="'.$this->getFieldName().'" value="'.$img.'">';
			}
			$ret .= '<input type="file" id="'.$this->getCSSID().'" name="'.$this->getFieldName().'"';
			if($this->isDelete()) {
				$ret .= ' readonly';
			}
			$ret .= '>';

			$ret .= $this->getErrorText();
			return $ret;
		}

		/**
		 * Returns the contents of this field for display in a list.
		 *
         * @param STRING $default Default value to use.
		 * @return STRING Current field value to use in a list.
		 */
		function getListView($default) {
			$options = $this->getOptions();
			$ret = '<img src="'.$options["path"].$default.'" width="'.$options["width"].'" height="'.$options["height"].'">';

			return $ret;
        }

        /**
		 * Checks to ensure that the given file name has a file extension in the provided list of valid extensions
		 *
		 * @param STRING $name Name of the file to check.
		 * @param ARRAY $exts Array of valid extensions (3 or 4 letters).
		 * @return BOOLEAN False if the given filename has an invalid file extension.
		 */
		protected function isCorrectType($name, $exts) {
			$ext1 = substr($name, strlen($name)-3);
			$ext2 = substr($name, strlen($name)-4);
			return in_array($ext1, $exts) || in_array($ext2, $exts);
		}

		/**
		 * Processes this field and update the backend used by this field.
		 *
		 * Uploaded images will be in the following format:
		 *				$file['name'] - The original name of the file on the client machine.
		 *				$file['type'] - The mime type of the file, if the browser provided this information. An example would be "image/gif". This mime type is however not checked on the PHP side and therefore don't take its value for granted.
		 *				$file['size'] - The size, in bytes, of the uploaded file.
		 *				$file['tmp_name'] - The temporary filename of the file in which the uploaded file was stored on the server.
		 *				$file['error'] - The error code associated with this file upload. See http://us2.php.net/manual/en/features.file-upload.errors.php for a list of error constants.
		 *
		 * @return BOOLEAN False if errors were encountered
		 */
		function process() {
			$options = $this->getOptions();
			$path = $options["path"];
			$exts = explode(",", $options["ext"]);

			$oldValue = $this->getValue();
            if(empty($oldValue)) {
                $oldValue = $_POST[$this->getFieldName()];
            }
            $value = $_FILES[$this->getFieldName()];
            $this->isEmpty = empty($value['name']) && empty($oldValue);
            //if there is an old value and no value was specified, return true and use the old value
			if(!empty($oldValue) && empty($value['name'])) {
                $this->setValue($oldValue);
				return true;
			} elseif($this->isRequired() && $this->isEmpty()) {
                $this->errorText = "Please provide an image";
				return false;
			}

            if($this->isDelete()) {
				return $this->deleteFile($path.$this->getValue());
			}

			if(!is_array($value)) {
				$msg = "The data for the field ".$this->getName()." was not an array and could not be processed";
				ErrorLogManager::log($msg, ErrorLogManager::FATAL);
				$this->errorText = "A fatal error occured - Contact your System Administrator<br>This error has been logged";
				return false;
			}

			if(empty($value['tmp_name'])) {
                $msg = "The file for the field ".$this->getName()." failed to be stored in a temporary file.";
				ErrorLogManager::log($msg, ErrorLogManager::FATAL);
				$this->errorText = "A fatal error occured - Contact your System Administrator<br>This error has been logged";
                return false;
			}

			if(!is_uploaded_file($value['tmp_name'])) {
				$msg = "The file for the field ".$this->getName()." could not be uploaded\n";
                $msg .= var_export($value, true);
				ErrorLogManager::log($msg, ErrorLogManager::FATAL);
				$this->errorText = "A fatal error occured - Contact your System Administrator<br>This error has been logged";
				return false;
			}

			if($value['size'] > Image::$maxSize) {
				$this->errorText = "The file was to large: Maximum size = 5mb";
				return false;
			}

			$value['name'] = strtolower($value['name']);
			if(!$this->isCorrectType($value['name'], $exts)) {
				$this->errorText = "The file must end in one of the following extensions: ".$options["ext"];
				return false;
			}
			//handle duplicate file names elegantly
			if(file_exists($path.$value['name'])) {
				if($this->getValue() == $value['name']) {
					$this->deleteFile($path.$value['name']);
                    $this->postProcess(null);
				} else {
					$temp = explode(".", $value['name']);
					for($i=1; file_exists($path.$temp[0].$i.$temp[1]); $i++) {}
					$value['name'] = $temp[0].$i.".".$temp[1];
				}
			}
			//move the file from its temporary location into the proper directory
			if(!move_uploaded_file($value['tmp_name'], $path.$value['name'])) {
				$msg = "Could not copy the image file for field ".$this->getName()." from its temporary directory";
				ErrorLogManager::log($msg, ErrorLogManager::FATAL);
				$this->errorText = "A fatal error occured - Contact your System Administrator<br>This error has been logged";
				return false;
			}

            //clean up the old file (if applicable)
			if(!empty($oldValue)) {
				$this->deleteFile($path.$oldValue);
			}

            return $this->postProcess($value['name']);
		}
	}
?>
