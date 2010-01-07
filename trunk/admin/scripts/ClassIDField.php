<?php
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");

    class ClassIDField extends Text {
        function process() {
            if(!parent::process()) {
                return false;
            }
            if(preg_match('/\\w{4}\\d{4}/', $this->getValue())) {
                return true;
            }
            $this->errorText = "Invalid class identifier";
            return false;
        }
    }
?>