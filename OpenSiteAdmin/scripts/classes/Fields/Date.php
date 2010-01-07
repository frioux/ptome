<?php
    class Date extends Field {
        /**
		 * Prepares this form field for display.
		 *
		 * @return STRING HTML to display for the form field
		 */
		function display() {
			$ret = "";
            $value = $this->getValue();
            $ret .= '<input type="text" id="DPC_'.$this->getFieldName().'" name="'.$this->getFieldName().'" value="'.$value.'" size="10" maxlength="10" datepicker="true" datepicker_format="YYYY-MM-DD", datepicker_min="'.date("Y-m-d").'">';
			$ret .= $this->getErrorText();
			return $ret;
		}

		/**
		 * Processes this field and update the backend used by this field.
		 *
		 * @return BOOLEAN False if errors were encountered
		 */
		function process() {
			$value = $_POST[$this->getFieldName()];
            $this->setEmpty($value);

			if($this->isRequired() && $this->isEmpty()) {
				$this->errorText = "Please enter a value";
				$this->setValue($value);
                return false;
			} elseif($this->isEmpty()) {
				return true;
			}
            $tmp = explode("-", $value);
            if(count($tmp) != 3 || strlen($tmp[0]) != 4 || strlen($tmp[1]) != 2 || strlen($tmp[2]) != 2) {
                $this->errorText = "Invalid date format: Expecting YYYY-MM-DD";
                $this->setValue($value);
                return false;
            }

			return $this->postProcess($value);
		}
    }
?>