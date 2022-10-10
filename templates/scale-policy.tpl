{
    "Constraints": {
        "MaxCapacity": 2,
        "MinCapacity": 1
    },
    "Rules": [
        {
            "Action": {
                "SimpleScalingPolicyConfiguration": {
                    "AdjustmentType": "CHANGE_IN_CAPACITY",
                    "CoolDown": 300,
                    "ScalingAdjustment": 1
                }
            },
            "Description": "Scale out if YARNMemoryAvailablePercentage is less than 15",
            "Name": "ScaleOutMemoryPercentage",
            "Trigger": {
                "CloudWatchAlarmDefinition": {
                    "ComparisonOperator": "LESS_THAN",
                    "EvaluationPeriods": 1,
                    "MetricName": "YARNMemoryAvailablePercentage",
                    "Namespace": "AWS/ElasticMapReduce",
                    "Period": 300,
                    "Statistic": "AVERAGE",
                    "Threshold": 15.0,
                    "Unit": "PERCENT"
                }
            }
        }
    ]
}
