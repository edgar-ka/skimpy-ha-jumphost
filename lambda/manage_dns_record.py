import boto3
import os

HOSTED_ZONE_ID = os.getenv('HOSTED_ZONE_ID')
DNS_RECORD = os.getenv('DNS_RECORD')
dnsclient = boto3.client('route53')
domain_name = dnsclient.get_hosted_zone(Id=HOSTED_ZONE_ID)["HostedZone"]["Name"]
FQDN = DNS_RECORD + "." + domain_name

def get_instance_ip(instance_id):
    """
    Get public IP address of instance by ID
    """
    ec2 = boto3.resource('ec2')
    inst = ec2.Instance(instance_id)
    return inst.public_ip_address

def create_record(zone_id, dns_name, ip_address):
    """
    Create instance DNS record in specified hosted zone
    """
    response = dnsclient.change_resource_record_sets(
        HostedZoneId=zone_id,
        ChangeBatch={
            'Comment': 'Record for bastion host',
            'Changes': [
                {
                    'Action': 'UPSERT',
                    'ResourceRecordSet': {
                        'Name': dns_name,
                        'Type': 'A',
                        'TTL': 60,
                        'ResourceRecords': [
                            {
                                'Value': ip_address
                            },
                        ],
                        }
                    },
            ]
        })
    return response

def delete_record(zone_id, dns_name, ip_address):
    """
    Delete Route53 record by dns name and IP
    """
    response = dnsclient.change_resource_record_sets(
        HostedZoneId=zone_id,
        ChangeBatch={
            'Comment': 'Record for bastion host',
            'Changes': [
                {
                    'Action': 'DELETE',
                    'ResourceRecordSet': {
                        'Name': dns_name,
                        'Type': 'A',
                        'TTL': 60,
                        'ResourceRecords': [
                            {
                                'Value': ip_address
                            },
                        ],
                    }
                },
            ]
        })
    return response

def lambda_handler(event, context):
    """
    Main function logic
    """
    asclient = boto3.client('autoscaling')
    if event["detail"]["LifecycleTransition"] == "autoscaling:EC2_INSTANCE_LAUNCHING":
        create_record(
            HOSTED_ZONE_ID,
            FQDN,
            get_instance_ip(event["detail"]["EC2InstanceId"])
        )
    elif event["detail"]["LifecycleTransition"] == "autoscaling:EC2_INSTANCE_TERMINATING":
        delete_record(
            HOSTED_ZONE_ID,
            FQDN,
            get_instance_ip(event["detail"]["EC2InstanceId"])
        )
    else:
        # TODO: implement logging to stdout
        pass
    asclient.complete_lifecycle_action(
        AutoScalingGroupName=event["detail"]["AutoScalingGroupName"],
        LifecycleActionToken=event["detail"]["LifecycleActionToken"],
        LifecycleHookName=event["detail"]["LifecycleHookName"],
        LifecycleActionResult='CONTINUE'
    )
