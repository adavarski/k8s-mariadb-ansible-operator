# MariaDB Operator for Kubernetes

[![Build Status](https://travis-ci.com/adavarski/k8s-mariadb-ansible-operator.svg?branch=master)](https://travis-ci.com/adavarski/k8s-mariadb-ansible-operator)

This is a MariaDB Operator (ansible-based), which makes management of MariaDB instances (or clusters) running inside Kuberenetes clusters easy. It was built with the [Operator SDK](https://github.com/operator-framework/operator-sdk) using [Ansible](https://www.ansible.com/blog/ansible-operator).  

The Operator SDK provides a way to build an Operator that will run Ansible playbooks to react to CR changes. The SDK supplies the code for the Kubernetes pieces,
such as the controller, allowing you to focus on writing the playbooks themselves.

If you want you can use ansible role and playbook file ts base and build similiar MariaDB Operator using Operator SDK.

```
$ cd ansible-base
$ OPERATOR_NAME=mariadb-ansible-operator
$ operator-sdk new $OPERATOR_NAME --api-version=mariadb.mariadb.com/v1alpha1 --kind=MariaDB --type=ansible
INFO[0000] Creating new Ansible operator 'mariadb-ansible-operator'. 
INFO[0000] Created deploy/service_account.yaml          
INFO[0000] Created deploy/role.yaml                     
INFO[0000] Created deploy/role_binding.yaml             
INFO[0000] Created deploy/crds/mariadb.mariadb.com_mariadbs_crd.yaml 
INFO[0000] Created deploy/crds/mariadb.mariadb.com_v1alpha1_mariadb_cr.yaml 
INFO[0000] Created build/Dockerfile                     
INFO[0000] Created roles/mariadb/README.md              
INFO[0000] Created roles/mariadb/meta/main.yml          
INFO[0000] Created roles/mariadb/files/.placeholder     
INFO[0000] Created roles/mariadb/templates/.placeholder 
INFO[0000] Created roles/mariadb/vars/main.yml          
INFO[0000] Created molecule/test-local/playbook.yml     
INFO[0000] Created roles/mariadb/defaults/main.yml      
INFO[0000] Created roles/mariadb/tasks/main.yml         
INFO[0000] Created molecule/default/molecule.yml        
INFO[0000] Created build/test-framework/Dockerfile      
INFO[0000] Created molecule/test-cluster/molecule.yml   
INFO[0000] Created molecule/default/prepare.yml         
INFO[0000] Created molecule/default/playbook.yml        
INFO[0000] Created build/test-framework/ansible-test.sh 
INFO[0000] Created molecule/default/asserts.yml         
INFO[0000] Created molecule/test-cluster/playbook.yml   
INFO[0000] Created roles/mariadb/handlers/main.yml      
INFO[0000] Created watches.yaml                         
INFO[0000] Created deploy/operator.yaml                 
INFO[0000] Created .travis.yml                          
INFO[0000] Created molecule/test-local/molecule.yml     
INFO[0000] Created molecule/test-local/prepare.yml      
INFO[0000] Project creation complete.                
``` 

Operator SDK generates a project skeleton and you can start editing (fixing/extending code).


## Development

### Setup k8s minikube-based development environment

Run script:

```
$ ./setup_environment.sh
```

Check:

```
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"16", GitVersion:"v1.16.2", GitCommit:"c97fe5036ef3df2967d086711e6c0c405941e14b", GitTreeState:"clean", BuildDate:"2019-10-15T19:18:23Z", GoVersion:"go1.12.10", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"16", GitVersion:"v1.16.2", GitCommit:"c97fe5036ef3df2967d086711e6c0c405941e14b", GitTreeState:"clean", BuildDate:"2019-10-15T19:09:08Z", GoVersion:"go1.12.10", Compiler:"gc", Platform:"linux/amd64"}
```

### Release Process

There are a few moving parts to this project:

  1. The Docker image which powers MariaDB Operator.
  2. The `mariadb-operator.yaml` Kubernetes manifest file which initially deploys the Operator into a cluster.

Each of these must be appropriately built in preparation for a new tag:

#### Build a new release of the Operator for Docker Hub

Run the following command inside this directory:
```
    $ operator-sdk build davarski/mariadb-ansible-operator:1.0.0
```
Then push the generated image to Docker Hub:
```
    $ docker login 
    $ docker push davarski/mariadb-ansible-operator:1.0.0
```
#### Build a new version of the `mariadb-operator.yaml` file

Verify the `build/chain-operator-files.yml` playbook has the most recent version/tag of the Docker image, then run the playbook in the `build/` directory:
```
    ansible-playbook chain-operator-files.yml
```
After it is built, test it on a local cluster:

```    
    kubectl apply -f deploy/mariadb-operator.yaml
    kubectl create namespace example-mariadb
    kubectl apply -f deploy/crds/mariadb_v1alpha1_mariadb_cr.yaml
    <test everything>
```

If everything is deployed correctly, commit the updated version and push it up to GitHub, tagging a new repository release with the same tag as the Docker image.

### Testing

#### Local tests with Molecule and KIND

Ensure you have the testing dependencies installed (in addition to Docker):
```
    pip install docker molecule openshift jmespath
```
Run the local molecule test scenario:
```
    molecule test -s test-local
```
#### Local tests with minikube

Running the Ansible Operator outside of the cluster:
```
$ cp watches.yaml local-watches.yaml
$ kubectl apply -f deploy/crds/*_crd.yaml
$ operator-sdk up local --watches-file ./local-watches.yaml
INFO[0000] Running the operator locally.
INFO[0000] Using namespace default.
```

### Operator Lifecycle Manager (OLM)

Check OLM:

```
$ kubectl get ns olm
$ kubectl get pods -n olm
$ kubectl get crd
$ kubectl get catalogsource -n olm
$ kubectl describe catalogsource/operatorhubio-catalog -n olm
$ kubectl get packagemanifest -n olm
```

OLM Bundle Creation
```
$ operator-sdk olm-catalog gen-csv --csv-version 1.0.0
INFO[0000] Generating CSV manifest version 1.0.0        
INFO[0000] Fill in the following required fields in file deploy/olm-catalog/mariadb-operator/1.0.0/mariadb-operator.v1.0.0.clusterserviceversion.yaml:
	spec.keywords
	spec.maintainers
	spec.provider 
INFO[0000] Created deploy/olm-catalog/mariadb-operator/1.0.0/mariadb-operator.v1.0.0.clusterserviceversion.yaml 
INFO[0000] Created deploy/olm-catalog/mariadb-operator/mariadb-operator.package.yaml 
$ mkdir -p olm/bundle
$ cp deploy/olm-catalog/mariadb-operator/1.0.0/mariadb-operator.v1.0.0.clusterserviceversion.yaml olm/bundle/
$ cp deploy/olm-catalog/mariadb-operator/mariadb-operator.package.yaml olm/bundle/
$ cp deploy/crds/mariadb_v1alpha1_mariadb_crd.yaml olm/bundle/
```
Edit bundle files:

Create the OperatorSource:

```
$ cd olm
$ kubectl apply -f operator-source.yaml
$ kubectl get catalogsource -n marketplace
$ kubectl get opsrc -n marketplace
```
If there are no bundles at the endpoint when you create the source, the status will
be Failed . You can ignore this for now; you’ll refresh this list later, once you’ve
uploaded a bundle.

Building the OLM Bundle:
```
$ operator-courier verify ./bundle
$ ./get-quay-token 
Username: davarski
Password: 

========================================
Auth Token is: basic XXXXXXXXXX=
The following command will assign the token to the expected variable:
  export QUAY_TOKEN="basic XXXXXXXXX="
$ OPERATOR_DIR=bundle
$ QUAY_NAMESPACE=davarski
PACKAGE_NAME=visitors-ansible-operator
PACKAGE_VERSION=1.0.0
QUAY_TOKEN="basic XXXXXXXXX="
$ operator-courier push "$OPERATOR_DIR" "$QUAY_NAMESPACE" \
"$PACKAGE_NAME" "$PACKAGE_VERSION" "$QUAY_TOKEN"

```
By default, bundles pushed to Quay.io in this fashion are marked as
private. Navigate to the image at https://quay.io/application/ and
mark it as public so that it is accessible to the cluster.


```
$ kubectl get pods -n marketplace 
$ kubectl delete pod davarski-operators-5969c68d68-vfff6 -n marketplace


$ kubectl delete -f operator-source.yaml
$ kubectl apply -f operator-source.yaml

$ OP_SRC_NAME=davarski-operators
$ kubectl get opsrc $OP_SRC_NAME -o=custom-columns=NAME:.metadata.name,PACKAGES:.status.packages -n marketplace
NAME                 PACKAGES
davarski-operators   mariadb-operator,visitors-ansible-operator
```

Installing the Operator Through OLM
```
$ kubectl apply -f operator-group.yaml
$ kubectl apply -f subscription.yaml
$ kubectl get pods -n marketplace
```

Cleaning up:
```
$ kubectl delete -f subscription.yaml
...

## Usage

This Kubernetes Operator is meant to be deployed in your Kubernetes cluster(s) and can manage one or more MariaDB database instances or clusters in any namespace.

First you need to deploy MariaDB Operator into your cluster:

    kubectl apply -f https://raw.githubusercontent.com/adavarski/k8s-mariadb-ansible-operator/master/deploy/mariadb-operator.yaml

or 
    kubectl apply -f deploy/mariadb-operator.yaml

Then you can create instances of MariaDB in any namespace, for example:

  1. Create a file named `my-database.yml` with the following contents:

     ```
     ---
     apiVersion: mariadb.mariadb.com/v1alpha1
     kind: MariaDB
     metadata:
       name: example-mariadb
       namespace: example-mariadb
     spec:
       masters: 1
       replicas: 0
       mariadb_password: CHANGEME
       mariadb_image: mariadb:10.4
       mariadb_pvc_storage_request: 1Gi
     ```

  2. Use `kubectl` to create the MariaDB instance in your cluster:

     ```
     kubectl apply -f my-database.yml
     ```

> You can also deploy `MariaDB` instances into other namespaces by changing `metadata.namespace`, or deploy multiple `MariaDB` instances into the same namespace by changing `metadata.name`.

### Connecting to the running database

Once the database instance has been deployed and initialized (this can take up to a few minutes), you can connect to it using the MySQL CLI from within the same namespace as your database instance, for example:

    kubectl -n example-mariadb run -it --rm mysql-client --image=arey/mysql-client --restart=Never -- -h example-mariadb-0.example-mariadb.example-mariadb.svc.cluster.local -u db_user -pCHANGEME -D db

Other applications can connect to the database instance from within the same namespace using the following connection parameters:

  - Host: `example-mariadb-0.example-mariadb.example-mariadb.svc.cluster.local`
  - Username: `db_user`
  - Password: `CHANGEME`
  - Database: `db`

### Exposing an instance to the outside world

You can also expose a database instance to the outside world by adding a `Service` to connect to port `3360`:

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: mariadb-master
      namespace: example-mariadb
    spec:
      type: NodePort
      selector:
        statefulset.kubernetes.io/example-mariadb: example-mariadb-0
      ports:
      - protocol: TCP
        port: 3360
        targetPort: 3360

Once you create that service in the same namespace, you can connect to MariaDB via the NodePort assigned to the service.


