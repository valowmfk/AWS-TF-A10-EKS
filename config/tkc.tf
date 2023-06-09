#
#  TKC Demo
#
#  SE Cloud Demo Team
#  A10 Networks, Inc.
#  May, 2022
#

provider "kubernetes" {
  config_path = var.prov_config_path
  config_context = "AWS-EKS-Cluster"
}

#------------------------------------------------------------------#
resource "kubernetes_namespace" "demo-ns" {
  depends_on = [
    thunder_virtual_server.ws-vip
  ]
  metadata {
    name = var.demo_namespace
  }
}

#------------------------------------------------------------------#
resource "kubernetes_cluster_role_binding" "rbac" {
  metadata {
    name = "th-secret-rbac"
  }
  subject {
    kind = "ServiceAccount"
    name = "default"
    namespace = kubernetes_namespace.demo-ns.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
  }
}

#------------------------------------------------------------------#
resource "kubernetes_secret" "thunder-secret" {
  metadata {
    name = "thunder-access-creds"
    namespace = kubernetes_namespace.demo-ns.metadata[0].name
  }
  data = {
    username = var.thunder_username
    password = var.thunder_password
  }
}

#------------------------------------------------------------------#
resource "kubernetes_config_map" "ws-config" {
  depends_on = [
    kubernetes_namespace.demo-ns
  ]
  metadata {
    name = "ws-conf-file"
    namespace = kubernetes_namespace.demo-ns.metadata[0].name
  }
  data = {
    "ws.conf" = <<EOF
    server {
        listen 80 default_server;
        server_name app_server;
        
        root /usr/share/nginx/html;
        error_log /var/log/nginx/app-server-error.log notice;
        index index.html;
        expires -1;
        
        sub_filter_once off;
        sub_filter 'server_hostname' '$hostname';
        sub_filter 'server_address'  '$server_addr:$server_port';
        sub_filter 'remote_addr'     '$remote_addr:$remote_port';
        sub_filter 'client_browser'  '$http_user_agent';
        sub_filter 'document_root'   '$document_root';
        sub_filter 'proxied_for_ip'  '$http_x_forwarded_for';
    }
    EOF
  }
}

#------------------------------------------------------------------#
resource "kubernetes_config_map" "ws-index" {
  depends_on = [
    kubernetes_namespace.demo-ns
  ]
  metadata {
    name = "ws-index-file"
    namespace = kubernetes_namespace.demo-ns.metadata[0].name
  }
  data = {
    "index.html" = <<EOF
    <!DOCTYPE html>
    <html>
        <head>
            <title>A10 Testing Webpage</title>
            <style>
                body {
                    margin: 0px;
                    font: 20px 'RobotoRegular', Arial, sans-serif;
                    font-weight: 100;
                    height: 100%;
                    color: #FFFFFF;
                }
                img {
                    width: 200px;
                    margin: 35px auto 35px auto;
                    display:block;
                }
                div.disp {
                    display: table;
                    background: #252F3E;
                    padding: 20px 20px 20px 20px;
                    border: 2px black;
                    border-radius: 12px;
                    margin: 0px auto auto auto;
                }
                div.disp p {
                    display: table-row;
                    margin: 5px auto auto auto;
                }
                div.disp p span {
                    display: table-cell;
                    padding: 10px;
                }
                h1, h2 {
                    font-weight: 100;
                }
                div.check {
                    padding: 0px 0px 0px 0px;
                    display: table;
                    margin: 35px auto auto auto;
                    font: 12px 'RobotoRegular', Arial, sans-serif;
                }
                #center {
                    width: 400px;
                    margin: 0 auto;
                    font: 12px Courier;
                }
            </style>
            <script>
                var ref;
                function checkRefresh() {
                    if (document.cookie == "refresh=1") {
                        document.getElementById("check").checked = true;
                        ref = setTimeout(function(){location.reload();}, 500);
                    } 
                }
                function changeCookie() {
                    if (document.getElementById("check").checked) {
                        document.cookie = "refresh=1";
                        ref = setTimeout(function(){location.reload();}, 500);
                    } else {
                        document.cookie = "refresh=0";
                        clearTimeout(ref);
                    }
                }
            </script>
        </head>
        <body onload="checkRefresh();">
            <div class="disp">
                <br>
                <h2>A10 Webserver Demo Page - AWS</h2>
                <p><span>This is a test web page running on Amazon AWS EKS.</span></p>
                <p><span>Server Name:</span> <span>server_hostname</span></p>
                <p><span>Server Address:</span> <span>server_address</span></p>
                <p><span>UA:</span> <span>client_browser</span></p>
            </div>
            <div class="check">
                <input type="checkbox" id="check" onchange="changeCookie()"> Auto Refresh</input>
            </div>
        </body>
    </html>
    EOF
  }
}

#------------------------------------------------------------------#
resource "kubernetes_deployment" "webservers" {
  depends_on = [
    kubernetes_config_map.ws-config,
    kubernetes_config_map.ws-index
  ]
  metadata {
    name = "webserver"
    namespace = kubernetes_namespace.demo-ns.metadata[0].name
  }
  spec {
    selector {
      match_labels = {
        app = "webserver"
      }
    }
    replicas = 3
    template {
      metadata {
        labels = {
          app = "webserver"
        }
      }
      spec {
        container {
          name = "nginx"
          image = "nginx:latest"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 80
          }
          volume_mount {
            mount_path = "/usr/share/nginx/html/index.html"
            sub_path = "index.html"
            read_only = true
            name = "ws-index-file"
          }
          volume_mount {
            mount_path = "/etc/nginx/conf.d/"
            read_only = true
            name = "ws-conf-file"
          }
        }
        volume {
          name = "ws-index-file"
          config_map {
            name = "ws-index-file"
            items {
              key = "index.html"
              path = "index.html"
            }
          }
        }
        volume {
          name = "ws-conf-file"
          config_map {
            name = "ws-conf-file"
            items {
              key = "ws.conf"
              path = "ws.conf"
            }
          }
        }
      }
    }
  }
}

#------------------------------------------------------------------#
resource "kubernetes_service" "webserverSvc" {
  depends_on = [
    kubernetes_deployment.webservers
  ]
  metadata {
    name = "webserver-svc"
    namespace = kubernetes_namespace.demo-ns.metadata[0].name
  }
  spec {
    selector = {
      app = "webserver"
    }
    type = "NodePort"
    port {
      name = "http-port"
      protocol = "TCP"
      port = "8080"
      target_port = "80"
    }
  }
}

#------------------------------------------------------------------#
resource "kubernetes_ingress_v1" "tkcIngress" {
  depends_on = [
    kubernetes_deployment.webservers,
    kubernetes_service.webserverSvc
  ]
  metadata {
    name = "ingress-resource"
    namespace = kubernetes_namespace.demo-ns.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "a10-ext"
      "acos.a10networks.com/health-monitors" = "[{\"name\":\"ws-mon\", \"port\":\"80\",\"type\":\"http\"}]"
      "webserver-svc.acos.a10networks.com/service-group" = "{\"name\":\"ws-sg\",\"protocol\":\"tcp\",\"monitor\":\"ws-mon\",\"disableMonitor\":false}"
      "acos.a10networks.com/virtual-server" = "{\"name\":\"ws-vip\",\"vip\":\"${var.thunder_vip}\"}"
      "acos.a10networks.com/virtual-ports" = "[{\"port\":\"80\",\"protocol\":\"http\",\"http2\":false,\"snat\":true}]"
    }
  }
  spec {
    rule {
      host = "a10cloudplatform.com"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "webserver-svc"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}

#------------------------------------------------------------------#
resource "kubernetes_deployment" "tkc" {
  depends_on = [
    kubernetes_ingress_v1.tkcIngress,
    kubernetes_secret.thunder-secret
  ]
  metadata {
    name = "thunder-kubernetes-connector"
    namespace = kubernetes_namespace.demo-ns.metadata[0].name
  }
  spec {
    selector {
      match_labels = {
        app = "thunder-kubernetes-connector"
      }
    }
    replicas = 1
    template {
      metadata {
        labels = {
          app = "thunder-kubernetes-connector"
        }
      }
      spec {
        container {
          name = "thunder-kubernetes-connector"
          image = "a10networks/a10-kubernetes-connector:2.1.1.0"
          image_pull_policy = "IfNotPresent"
          env {
            name = "POD_NAMESPACE"
            value = kubernetes_namespace.demo-ns.metadata[0].name
          }
          env {
            name = "WATCH_NAMESPACE"
            value = kubernetes_namespace.demo-ns.metadata[0].name
          }
          env {
            name = "CONTROLLER_URL"
            value = "https://${var.thunder_ip_address}"
          }
          env {
            name = "ACOS_USERNAME_PASSWORD_SECRETNAME"
            value = kubernetes_secret.thunder-secret.metadata[0].name
          }
          args = [
            "--watch-namespace=$(WATCH_NAMESPACE)",
            "--use-node-external-ip=false", # This must be set to false for public clouds (AWS, Azure, OCI, GCP, etc.) or it pulls the External IP
            "--patch-to-update=true",
            "--safe-acos-delete=true",
            "--use-ingress-class-only=true",
            "--ingress-class=a10-ext"
          ]
        }
      }
    }
  }
}

