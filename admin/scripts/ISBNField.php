<?php
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");

    /**
	 * Handles display and processing of a Text field designed specifically to process ISBN numbers.
	 *
	 * OPTIONAL<br>
	 * $options["size"] - size of the form's text input field<br>
	 * $options["maxlength"] - maximum length of text input field<br>
	 */
    class ISBNField extends Text {
        /**
		 * Processes this field and update the backend used by this field.
		 *
		 * @see validateISBN()
		 * @return BOOLEAN False if errors were encountered
		 */
        function process() {
            $ret = parent::process();
            $value = $this->getValue();
            $valid = validateISBN($value);
            if(!empty($value)) {
                if($ret && strlen($value) != 10 && strlen($value) != 13) {
                    $this->errorText .= "ISBN numbers must be 10 or 13 characters long";
                    return false;
                }
                if($this->getOptions() == 13 && strlen($value) != 13) {
                    $this->errorText .= "ISBN numbers must be 13 characters long";
                    return false;
                }
                if($this->getOptions() == 10 && strlen($value) != 10) {
                    $this->errorText .= "ISBN numbers must be 10 characters long";
                    return false;
                }
                if($valid != 0) {
                   $this->errorText .= "The ISBN you entered is not valid.";
                   return false;
                }
            }
            return $ret;
        }
    }

    /**
    *  Validates ISBN numbers
    *
    *  Algorithms can be found here:
    *  http://en.wikipedia.org/wiki/International_Standard_Book_Number
    *
    *  @param STRING $isbn An ISBN number
    *  @return INTEGER 0 - Valid<br>
    *                  1 - Invalid<br>
    *                  2 - Wrong length<br>
    */
   function validateISBN($isbn) {
      if(strlen($isbn) == 13) {
         $k = 0;
         for($i = 0; $i < 6; $i++) {
            $evenSum += intval($isbn[$k]);
            $k = $k + 2;
         }
         $k = 1;
         for($i = 0; $i < 6; $i++) {
            $oddSum += (3*intval($isbn[$k]));
            $k = $k + 2;
         }
         $checkValue = 10 - (($oddSum + $evenSum) % 10);

         if($checkValue == 10) {
            $checkValue = 0;
         }
      }
      else if (strlen($isbn) == 10) {
         for($i = 1; $i < 10; $i++) {
            $sum += intval($isbn[$i-1]) * $i;
         }
         $checkValue = ($sum % 11);

         if($checkValue == 11){
            $checkValue = 0;
         } else if($checkValue == 10) {
            $checkValue = "X";
         }
      } else {
         return 2;
      }

      if(intval($isbn[strlen($isbn)-1]) == intval($checkValue)) {
         return 0;
      } else {
         return 1;
      }
   }
?>
