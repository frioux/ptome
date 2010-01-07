<?php
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");

	class SemesterPicker extends Select {
        /**
		 * Constructs a form field with information on how to display it.
		 *
		 * @param STRING $name The name of the database field this form field corresponds to.
		 * @param STRING $title The title to display for this form field.
		 * @param MIXED $options The options associated with this form field.
		 * @param BOOLEAN $inList True if this field should be used in a list view.
		 * @param BOOLEAN $required True if this form field is required.
		 */
		function __construct($name, $title, $options, $inList, $required=false) {
            parent::__construct($name, $title, $this->getSemesterData(), $inList, $required);
        }

        function getSemesterData() {
            //rollover on March 1st, and October 20th
            $year = date("Y");
            $month = date("m");
            $day = date("d");
            $ret = array();
            $yearsBack = 1;
            if($month < 3) {
                $ret[($year).".25"] = "Spring ".($year);
                for($i = 1; $i < $yearsBack+1; $i++) {
                    $ret[($year-$i).".75"] = "Fall ".($year-$i);
                    $ret[($year-$i).".5"] = "Summer ".($year-$i);
                    $ret[($year-$i).".25"] = "Spring ".($year-$i);
                }
            } elseif($month >= 10 && $day >= 20) {
                $ret[($year+1).".25"] = "Spring ".($year+1);
                for($i = 0; $i < $yearsBack; $i++) {
                    $ret[($year-$i).".75"] = "Fall ".($year-$i);
                    $ret[($year-$i).".5"] = "Summer ".($year-$i);
                    $ret[($year-$i).".25"] = "Spring ".($year-$i);
                }
            } else {
                for($i = 0; $i < $yearsBack; $i++) {
                    $ret[($year-$i).".75"] = "Fall ".($year-$i);
                    $ret[($year-$i).".5"] = "Summer ".($year-$i);
                    $ret[($year-$i).".25"] = "Spring ".($year-$i);
                }
            }
            return $ret;
        }
	}
?>
