<?php
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");

    class ISBNField extends Text {
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
    *  Algorithms can be found here:
    *  http://en.wikipedia.org/wiki/International_Standard_Book_Number
    *
    *  @param   isbn  an ISBN number as a string
    *  @return        0 - Valid
    *                 1 - Invalid
    *                 2 - Wrong length
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
